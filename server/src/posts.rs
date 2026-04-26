/*
*        create table if not exists posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT NOT NULL,
            publish_unix_time INTEGER DEFAULT 9223372036854775807

*
*/

use libsql::{params, Builder};
use rocket::{
    response::status::{self, Accepted},
    serde::json::Json,
};
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

    let mut posts: Vec<Post> = Vec::new();

    while let Some(row) = rows.next().await? {
        let id: i64 = row.get(0)?;
        let path: String = row.get(1)?;
        let publish_unix_time: u64 = row.get(2)?;
        let publish_time = Instant::at(publish_unix_time, 0u32);

        posts.push(Post {
            id,
            path,
            publish_time,
        })
    }

    Ok(posts)
}

#[derive(Serialize, Deserialize)]
pub struct NewPost {
    path: String,
}

#[post("/admin/post", data = "<path>")]
pub async fn create_post(path: Json<String>) -> Accepted<String> {
    db_create_post(path.0).await.unwrap();

    Accepted("true".to_string())
}

async fn db_create_post(path: String) -> libsql::Result<()> {
    let db = Builder::new_local("blog.db").build().await?;
    let conn = db.connect()?;

    conn.execute("insert into posts (path) values (?1)", [&*path])
        .await?;

    Ok(())
}

#[put("/admin/post/<post_id>", data = "<json_post>")]
pub async fn update_post(post_id: i64, json_post: Json<Post>) -> Accepted<String> {
    let post = json_post.0;
    if post_id != post.id {
        panic!("You're updating the wrong post!")
    }

    db_update_post(post).await.unwrap();

    status::Accepted("true".to_string())
}

async fn db_update_post(post: Post) -> libsql::Result<()> {
    let db = Builder::new_local("blog.db").build().await?;
    let conn = db.connect()?;

    conn.execute(
        "update posts set path=?1, publish_time=?2 where id=?3",
        params![&*post.path, post.publish_time.secs(), post.id],
    )
    .await?;

    Ok(())
}
