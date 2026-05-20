use std::net::SocketAddr;

use libsql::{Database, Result, params};
use rocket::{State, response::status::Accepted, serde::json::Json};
use serde::{Deserialize, Serialize};
use unix_time::Instant;

#[derive(Serialize, Deserialize)]
pub struct Comment {
    commented_by: String,
    commented_at: u64,
    content: String,
}

#[get("/post/<post_id>/comments")]
pub async fn get_comments_by_post(post_id: i64, db: &State<Database>) -> Json<Vec<Comment>> {
    Json(db_get_comments_by_post(post_id, db).await.unwrap())
}

async fn db_get_comments_by_post(post_id: i64, db: &Database) -> libsql::Result<Vec<Comment>> {
    let conn = db.connect()?;

    let mut rows = conn
        .query(
            r#"
        SELECT commented_by, commented_at, content
        FROM comments
        WHERE post_id=?1 and approved=?2
        ORDER BY commented_at desc"#,
            libsql::params![post_id, approval_to_id(true)],
        )
        .await?;

    let mut comments: Vec<Comment> = Vec::new();

    while let Some(row) = rows.next().await? {
        let commented_by: String = row.get(0)?;
        let commented_at: u64 = row.get(1)?;
        let content: String = row.get(2)?;

        comments.push(Comment {
            commented_by,
            commented_at,
            content,
        })
    }

    Ok(comments)
}

#[derive(Serialize, Deserialize)]
pub struct NewComment {
    member_id: i64,
    commented_by: String,
    content: String,
}

#[post("/post/<post_id>/comment", data = "<comment_json>")]
pub async fn create_comment(
    remote_addr: SocketAddr,
    post_id: i64,
    comment_json: Json<NewComment>,
    db: &State<Database>,
) -> Accepted<String> {
    let comment = comment_json.0;

    db_create_comment(post_id, remote_addr, comment, db)
        .await
        .unwrap();

    Accepted("true".to_string())
}

async fn db_create_comment(
    post_id: i64,
    remote_addr: SocketAddr,
    comment: NewComment,
    db: &State<Database>,
) -> libsql::Result<()> {
    let conn = db.connect()?;

    conn.execute(
        r#"insert into comments (
            member_id,
            post_id,
            remote_addr,
            commented_by,
            commented_at,
            content,
            approved
        ) values (?1, ?2, ?3, ?4, ?5, ?6, ?7)"#,
        params![
            comment.member_id,
            post_id,
            remote_addr.ip().to_string(),
            comment.commented_by,
            Instant::now().secs(),
            comment.content,
            false
        ],
    )
    .await?;

    Ok(())
}

#[derive(Serialize, Deserialize)]
pub struct AdminComment {
    id: i64,
    member_id: i64,
    post_id: i64,
    remote_addr: String,
    commented_by: String,
    commented_at: u64,
    content: String,
    approved: i64,
}

#[get("/admin/comments")]
pub async fn get_comments(db: &State<Database>) -> Json<Vec<AdminComment>> {
    Json(db_get_comments(db).await.unwrap())
}

async fn db_get_comments(db: &Database) -> libsql::Result<Vec<AdminComment>> {
    let conn = db.connect()?;

    let mut rows = conn
        .query(
            r#"
            SELECT id, member_id, post_id, remote_addr, commented_by, commented_at, content, approved, commented_at 
            FROM comments"#,
            (),
        )
        .await?;

    let mut comments: Vec<AdminComment> = Vec::new();

    while let Some(row) = rows.next().await? {
        let id: i64 = row.get(0)?;
        let member_id: i64 = row.get(1)?;
        let post_id: i64 = row.get(2)?;
        let remote_addr: String = row.get(3)?;
        let commented_by: String = row.get(4)?;
        let commented_at: u64 = row.get(5)?;
        let content: String = row.get(6)?;
        let approved: i64 = row.get(7)?;

        comments.push(AdminComment {
            id,
            member_id,
            post_id,
            remote_addr,
            commented_by,
            commented_at,
            content,
            approved,
        })
    }

    Ok(comments)
}

#[put("/admin/comment/<comment_id>", data = "<comment_json>")]
pub async fn update_comment(
    comment_id: i64,
    comment_json: Json<AdminComment>,
    db: &State<Database>,
) -> Json<Vec<AdminComment>> {
    let comment = comment_json.0;
    if comment_id != comment.id {
        panic!("You're updating the wrong comment!");
    }

    db_update_comment(comment, db).await.unwrap();

    get_comments(db).await
}

async fn db_update_comment(comment: AdminComment, db: &Database) -> Result<()> {
    let conn = db.connect()?;

    conn.execute(
        r#"update comments set
            approved = ?2
        where id=?1"#,
        params![comment.id, comment.approved],
    )
    .await?;

    Ok(())
}

#[delete("/admin/comments/<remote_addr>")]
pub async fn delete_comments(remote_addr: &str, db: &State<Database>) -> Json<Vec<AdminComment>> {
    db_delete_comments(remote_addr, db).await.unwrap();

    get_comments(db).await
}

async fn db_delete_comments(remote_addr: &str, db: &Database) -> Result<()> {
    let conn = db.connect()?;

    conn.execute(
        r#"delete from comments where remote_addr=?1"#,
        params![remote_addr],
    )
    .await?;

    Ok(())
}

#[delete("/admin/comment/<comment_id>")]
pub async fn delete_comment(comment_id: i64, db: &State<Database>) -> Json<Vec<AdminComment>> {
    db_delete_comment(comment_id, db).await.unwrap();

    get_comments(db).await
}

async fn db_delete_comment(comment_id: i64, db: &Database) -> Result<()> {
    let conn = db.connect()?;

    conn.execute(r#"delete from comments where id=?1"#, params![comment_id])
        .await?;

    Ok(())
}

fn approval_to_id(approval: bool) -> i64 {
    if approval { 1 } else { 2 }
}

#[cfg(test)]
mod tests {
    use crate::launch::rocket;
    use libsql::Builder;
    use rocket::{http::Status, local::asynchronous::Client};

    use crate::schema;

    use super::*;

    #[tokio::test]
    async fn comment_administration_works() {
        let db = Builder::new_local("comments_tests.db")
            .build()
            .await
            .unwrap();
        schema::migrate(&db).await.unwrap();

        let client = Client::tracked(rocket(db))
            .await
            .expect("valid rocket instance");

        // create comment
        // not visible on post
        test_comment_creation(&client).await;

        // can see comment in admin
        // can approve/disapprove comment
        // approved visible on post
        test_approve_comment(&client).await;
        test_reject_comment(&client).await;

        // can delete on id
        test_admin_single_delete(&client).await;
        // create stores ip
        // can delete on ip
        test_admin_mass_delete(&client).await;
    }

    async fn test_comment_creation(client: &Client) {
        // Get comments before create
        let pre_comments = test_get_comments_by_post(client, 1).await;

        // Create comment
        test_create_comment(client).await;

        // Check created comment isn't visible
        let comments = test_get_comments_by_post(client, 1).await;
        assert_eq!(pre_comments.len(), comments.len());
    }

    async fn test_create_comment(client: &Client) {
        let response = client
            .post(uri!(create_comment(1)))
            .remote("123.123.123.123:123".parse().unwrap())
            .json(&NewComment {
                member_id: 1,
                commented_by: "123.123.12.12".to_string(),
                content: "".to_string(),
            })
            .dispatch()
            .await;
        assert_eq!(response.status(), Status::Accepted);
    }

    async fn test_approve_comment(client: &Client) {
        // Get all comments
        let mut comments = test_get_comments_not_empty(0, client).await;

        let comment = comments.get_mut(0).unwrap();
        let pre_comments = test_get_comments_by_post(client, comment.post_id).await;

        test_update_comment(1, client, comment).await;

        let comments = test_get_comments_by_post(client, comment.post_id).await;

        // Check comment is visible
        assert_ne!(pre_comments.len(), comments.len());
    }

    async fn test_reject_comment(client: &Client) {
        // Get all comments
        let mut comments = test_get_comments_not_empty(1, client).await;
        let comment = comments.get_mut(0).unwrap();

        let pre_comments = test_get_comments_by_post(client, comment.post_id).await;

        test_update_comment(2, client, comment).await;

        let comments = test_get_comments_by_post(client, comment.post_id).await;

        // Check comment is visible
        assert_ne!(pre_comments.len(), comments.len());
    }

    async fn test_update_comment(
        approval: i64,
        client: &Client,
        comment: &mut AdminComment,
    ) -> Vec<AdminComment> {
        comment.approved = approval;
        let response = client
            .put(uri!(super::update_comment(comment.id)))
            .json(comment)
            .dispatch()
            .await;
        assert_eq!(response.status(), Status::Ok);
        let comments: Vec<AdminComment> =
            serde_json::from_str(&response.into_string().await.unwrap()).unwrap();

        comments
    }

    async fn test_get_comments_by_post(client: &Client, post_id: i64) -> Vec<Comment> {
        let response = client
            .get(uri!(get_comments_by_post(post_id)))
            .dispatch()
            .await;
        assert_eq!(response.status(), Status::Ok);
        let comments: Vec<Comment> =
            serde_json::from_str(&response.into_string().await.unwrap()).unwrap();

        comments
    }

    async fn test_get_comments(approval: i64, client: &Client) -> Vec<AdminComment> {
        let response = client.get(uri!(super::get_comments())).dispatch().await;
        assert_eq!(response.status(), Status::Ok);
        let mut comments: Vec<AdminComment> =
            serde_json::from_str(&response.into_string().await.unwrap()).unwrap();
        comments.retain(|c| c.approved == approval);

        comments
    }

    async fn test_get_comments_not_empty(approval: i64, client: &Client) -> Vec<AdminComment> {
        let comments = test_get_comments(approval, client).await;
        assert_ne!(comments.len(), 0);

        comments
    }

    async fn test_admin_single_delete(client: &Client) {
        test_create_comment(client).await;
        let pre_comments = test_get_comments_not_empty(0, client).await;
        let comment = pre_comments.get(0).unwrap();

        let response = client
            .delete(uri!(super::delete_comment(&comment.id)))
            .dispatch()
            .await;
        assert_eq!(response.status(), Status::Ok);
        let comments: Vec<AdminComment> =
            serde_json::from_str(&response.into_string().await.unwrap()).unwrap();
        assert_ne!(pre_comments.len(), comments.len());
    }

    async fn test_admin_mass_delete(client: &Client) {
        test_create_comment(client).await;
        let pre_comments = test_get_comments_not_empty(0, client).await;
        let comment = pre_comments.get(0).unwrap();

        let response = client
            .delete(uri!(super::delete_comments(&comment.remote_addr)))
            .dispatch()
            .await;
        assert_eq!(response.status(), Status::Ok);
        let comments: Vec<AdminComment> =
            serde_json::from_str(&response.into_string().await.unwrap()).unwrap();
        assert_ne!(pre_comments.len(), comments.len());
    }
}
