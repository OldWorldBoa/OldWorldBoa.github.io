use libsql::{Database, params};
use rocket::{
    State,
    response::status::{self, Accepted},
    serde::json::Json,
};
use serde::{Deserialize, Serialize};
use unix_time::Instant;

#[derive(Serialize, Deserialize, Clone)]
pub struct Post {
    id: i64,
    path: String,
    publish_time: Instant,
}

#[get("/posts")]
pub async fn get_posts(db: &State<Database>) -> Json<Vec<Post>> {
    Json(db_get_posts(db).await.unwrap())
}

async fn db_get_posts(db: &State<Database>) -> libsql::Result<Vec<Post>> {
    let mut rows = db
        .connect()?
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
pub async fn create_post(path: Json<String>, db: &State<Database>) -> Accepted<String> {
    db_create_post(path.0, db).await.unwrap();

    Accepted("true".to_string())
}

async fn db_create_post(path: String, db: &State<Database>) -> libsql::Result<()> {
    db.connect()?
        .execute("insert into posts (path) values (?1)", [&*path])
        .await?;

    Ok(())
}

#[put("/admin/post/<post_id>", data = "<json_post>")]
pub async fn update_post(
    post_id: i64,
    json_post: Json<Post>,
    db: &State<Database>,
) -> Accepted<String> {
    let post = json_post.0;
    if post_id != post.id {
        panic!("You're updating the wrong post!")
    }

    db_update_post(post, db).await.unwrap();

    status::Accepted("true".to_string())
}

async fn db_update_post(post: Post, db: &State<Database>) -> libsql::Result<()> {
    db.connect()?
        .execute(
            "update posts set path=?1, publish_unix_time=?2 where id=?3",
            params![&*post.path, post.publish_time.secs(), post.id],
        )
        .await?;

    Ok(())
}

#[delete("/admin/post/<post_id>")]
pub async fn delete_post(post_id: i64, db: &State<Database>) -> Accepted<String> {
    db_delete_post(post_id, db).await.unwrap();

    status::Accepted("true".to_string())
}

async fn db_delete_post(post_id: i64, db: &State<Database>) -> libsql::Result<()> {
    db.connect()?
        .execute("delete from posts where id=?1", [post_id])
        .await?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use libsql::Result;
    use std::time::Duration;

    use crate::launch::rocket;
    use crate::schema;
    use libsql::Builder;
    use rocket::http::Status;
    use rocket::local::asynchronous::Client;

    #[tokio::test]
    async fn test_crud() -> Result<()> {
        let db = Builder::new_local("posts_tests.db").build().await.unwrap();
        schema::migrate(&db).await?;

        let client = Client::tracked(rocket(db))
            .await
            .expect("valid rocket instance");

        let response = client
            .post(uri!(super::create_post()))
            .json(&"test_path".to_string())
            .dispatch()
            .await;
        assert_eq!(response.status(), Status::Accepted);
        assert_eq!("true".to_string(), response.into_string().await.unwrap());

        let response = client.get(uri!(super::get_posts())).dispatch().await;
        assert_eq!(response.status(), Status::Ok);
        let mut posts: Vec<Post> =
            serde_json::from_str(&response.into_string().await.unwrap()).unwrap();
        posts.retain(|p| p.path == "test_path");
        assert_ne!(0, posts.len());

        let test_post = posts.get_mut(0);
        match test_post {
            Some(post) => {
                post.publish_time = Instant::from(Duration::from_hours(2));
                let response = client
                    .put(uri!(super::update_post(post.id)))
                    .json(post)
                    .dispatch()
                    .await;
                assert_eq!(response.status(), Status::Accepted);
                assert_eq!("true".to_string(), response.into_string().await.unwrap());
            }
            None => panic!("Post missing!"),
        }

        let response = client.get(uri!(super::get_posts())).dispatch().await;
        assert_eq!(response.status(), Status::Ok);
        posts = serde_json::from_str(&response.into_string().await.unwrap()).unwrap();
        posts.retain(|p| p.path == "test_path");
        assert_ne!(0, posts.len());

        let test_post = posts.get_mut(0);
        match test_post {
            Some(post) => {
                assert_eq!(Instant::from(Duration::from_hours(2)), post.publish_time);
            }
            None => panic!("Post missing!"),
        }

        for post in posts.iter() {
            let response = client
                .delete(uri!(super::delete_post(post.id)))
                .dispatch()
                .await;
            assert_eq!(response.status(), Status::Accepted);
            assert_eq!("true".to_string(), response.into_string().await.unwrap());
        }

        let response = client.get(uri!(super::get_posts())).dispatch().await;
        assert_eq!(response.status(), Status::Ok);
        posts = serde_json::from_str(&response.into_string().await.unwrap()).unwrap();
        posts.retain(|p| p.path == "test_path");
        assert_eq!(0, posts.len());

        Ok(())
    }
}
