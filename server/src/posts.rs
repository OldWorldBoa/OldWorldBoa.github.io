/*
*        create table if not exists posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT NOT NULL,
            publish_unix_time INTEGER DEFAULT 9223372036854775807

*
*/

use libsql::Builder;
use rocket::serde::json::Json;
use serde::{Deserialize, Serialize};
use unix_time::Instant;

#[derive(Serialize, Deserialize)]
pub struct Post {
    id: i64,
    path: String,
    publish_time: Instant,
}

#[get("/posts")]
pub async fn get_posts() -> Json<Vec<Post>> {
    Json(db_get_posts().await.unwrap())
}

async fn db_get_posts() -> libsql::Result<Vec<Post>> {
    let db = Builder::new_local("blog.db").build().await?;
    let conn = db.connect()?;

    let mut rows = conn
        .query(
            r#"
        SELECT id, path, publish_unix_time
        FROM posts"#,
            (),
        )
        .await?;

    let mut comments: Vec<Post> = Vec::new();

    while let Some(row) = rows.next().await? {
        let id: i64 = row.get(0)?;
        let path: String = row.get(1)?;
        let publish_unix_time: u64 = row.get(2)?;
        let publish_time = Instant::at(publish_unix_time, 0u32);

        comments.push(Post {
            id,
            path,
            publish_time,
        })
    }

    Ok(comments)
}

#[post("/posts", data = "<post>")]
pub async fn create_post(post: Json<Post>) {}
