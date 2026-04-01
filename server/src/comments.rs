use libsql::Builder;
use rocket::serde::json::Json;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct Comment {
    id: i64,
    user_id: i64,
    post_id: i64,
    content: String,
    approved: bool,
}

#[get("/comment/<post_id>")]
pub async fn get_comments_by_post(post_id: i64) -> Json<Vec<Comment>> {
    Json(db_get_comments_by_post(post_id).await.unwrap())
}

async fn db_get_comments_by_post(post_id: i64) -> libsql::Result<Vec<Comment>> {
    let db = Builder::new_local("blog.db").build().await?;
    let conn = db.connect()?;

    let mut rows = conn
        .query(
            r#"
        SELECT id, user_id, post_id, content, approved, commented_at 
        FROM comments
        WHERE post_id=?1"#,
            libsql::params![post_id],
        )
        .await?;

    let mut comments: Vec<Comment> = Vec::new();

    while let Some(row) = rows.next().await? {
        let id: i64 = row.get(0)?;
        let user_id: i64 = row.get(1)?;
        let post_id: i64 = row.get(2)?;
        let content: String = row.get(3)?;
        let approved_num: i64 = row.get(4)?;
        let approved = approved_num > 0;

        comments.push(Comment {
            id,
            user_id,
            post_id,
            content,
            approved,
        })
    }

    Ok(comments)
}
