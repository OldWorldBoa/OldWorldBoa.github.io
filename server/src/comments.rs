use libsql::{params, Builder};
use rocket::{response::status::Accepted, serde::json::Json};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct Comment {
    id: i64,
    member_id: i64,
    post_id: i64,
    commented_by: String,
    content: String,
    approved: bool,
}

#[get("/admin/post/<post_id>/unread_comments")]
pub async fn get_unread_comments(post_id: i64) {}

#[get("/post/<post_id>/comments")]
pub async fn get_comments_by_post(post_id: i64) -> Json<Vec<Comment>> {
    Json(db_get_comments_by_post(post_id).await.unwrap())
}

async fn db_get_comments_by_post(post_id: i64) -> libsql::Result<Vec<Comment>> {
    let db = Builder::new_local("blog.db").build().await?;
    let conn = db.connect()?;

    let mut rows = conn
        .query(
            r#"
        SELECT id, member_id, post_id, commented_by, content, approved, commented_at 
        FROM comments
        WHERE post_id=?1 and approved=?2"#,
            libsql::params![post_id, true],
        )
        .await?;

    let mut comments: Vec<Comment> = Vec::new();

    while let Some(row) = rows.next().await? {
        let id: i64 = row.get(0)?;
        let member_id: i64 = row.get(1)?;
        let post_id: i64 = row.get(2)?;
        let commented_by: String = row.get(3)?;
        let content: String = row.get(4)?;
        let approved_num: i64 = row.get(5)?;
        let approved = approved_num > 0;

        comments.push(Comment {
            id,
            member_id,
            post_id,
            commented_by,
            content,
            approved,
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
pub async fn create_comment(post_id: i64, comment_json: Json<NewComment>) -> Accepted<String> {
    let comment = comment_json.0;

    db_create_comment(post_id, comment).await.unwrap();

    Accepted("true".to_string())
}

async fn db_create_comment(post_id: i64, comment: NewComment) -> libsql::Result<()> {
    let db = Builder::new_local("blog.db").build().await?;
    let conn = db.connect()?;

    conn.execute(
        r#"insert into comments (
            member_id,
            post_id,
            commented_by,
            content,
            approved
        ) values (?1, ?2, ?3, ?4, ?5)"#,
        params![
            comment.member_id,
            post_id,
            comment.commented_by,
            comment.content,
            false
        ],
    )
    .await?;

    Ok(())
}
