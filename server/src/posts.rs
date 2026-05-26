use libsql::{Database, Error};
use rocket::{
    State,
    http::Status,
    response::status::{self, Accepted},
    serde::json::Json,
};
use serde::{Deserialize, Serialize};
use unix_time::Instant;

use crate::security::FromLocal;

#[derive(Serialize, Deserialize, Clone)]
pub struct Post {
    id: i64,
    path: String,
    publish_time: u64,
    title: String,
    author: String,
    tags: String,
    preview: String,
}

#[get("/posts")]
pub async fn get_published_posts(db: &State<Database>) -> Json<Vec<Post>> {
    Json(db_get_posts(true, db).await.unwrap())
}

#[get("/admin/posts")]
pub async fn get_all_posts(_from_local: FromLocal, db: &State<Database>) -> Json<Vec<Post>> {
    Json(db_get_posts(false, db).await.unwrap())
}

async fn db_get_posts(filter_published: bool, db: &State<Database>) -> libsql::Result<Vec<Post>> {
    let mut query =
        r#"SELECT id, path, title, author, tags, preview, publish_unix_time FROM posts"#.to_owned();
    let filter;
    let params;
    if filter_published {
        filter = " WHERE publish_unix_time < ?1";
        params = [Instant::now().secs() * 1000];
    } else {
        filter = " WHERE 1=?1";
        params = [1];
    }
    query.push_str(filter);

    let mut rows = db.connect()?.query(&query, params).await?;

    let mut posts: Vec<Post> = Vec::new();

    while let Some(row) = rows.next().await? {
        let id: i64 = row.get(0)?;
        let path: String = row.get(1)?;
        let title: String = row.get(2)?;
        let author: String = row.get(3)?;
        let tags: String = row.get(4)?;
        let preview: String = row.get(5)?;
        let publish_time: u64 = row.get(6)?;

        posts.push(Post {
            id,
            path,
            publish_time,
            title,
            author,
            tags,
            preview,
        })
    }

    Ok(posts)
}

#[get("/post/<post_path>")]
pub async fn get_post(post_path: &str, db: &State<Database>) -> Result<Json<Post>, Status> {
    match db_get_post(post_path, db).await {
        Ok(post) => Ok(Json(post)),
        Err(e) => match e {
            Error::QueryReturnedNoRows => Err(Status::NotFound),
            _ => Err(Status::InternalServerError),
        },
    }
}

async fn db_get_post(post_path: &str, db: &Database) -> libsql::Result<Post> {
    let query =
        r#"SELECT id, path, title, author, tags, preview, publish_unix_time FROM posts WHERE path = ?1"#.to_owned();

    let mut rows = db.connect()?.query(&query, [post_path]).await?;

    if let Some(row) = rows.next().await? {
        let id: i64 = row.get(0)?;
        let path: String = row.get(1)?;
        let title: String = row.get(2)?;
        let author: String = row.get(3)?;
        let tags: String = row.get(4)?;
        let preview: String = row.get(5)?;
        let publish_time: u64 = row.get(6)?;

        Ok(Post {
            id,
            path,
            publish_time,
            title,
            author,
            tags,
            preview,
        })
    } else {
        Err(Error::QueryReturnedNoRows)
    }
}

#[derive(Serialize, Deserialize)]
pub struct NewPost {
    path: String,
    author: String,
    title: String,
    preview: String,
    tags: String,
}

#[post("/admin/post", data = "<new_post>")]
pub async fn create_post(
    new_post: Json<NewPost>,
    _from_local: FromLocal,
    db: &State<Database>,
) -> Json<Vec<Post>> {
    db_create_post(new_post.0, db).await.unwrap();

    Json(db_get_posts(false, db).await.unwrap())
}

async fn db_create_post(new_post: NewPost, db: &State<Database>) -> libsql::Result<()> {
    db.connect()?
        .execute(
            "insert into posts (path, author, title, preview, tags) values (?1, ?2, ?3, ?4, ?5)",
            [
                &*new_post.path,
                &*new_post.author,
                &*new_post.title,
                &*new_post.preview,
                &*new_post.tags,
            ],
        )
        .await?;

    Ok(())
}

#[put("/admin/post/<post_id>", data = "<json_post>")]
pub async fn update_post(
    post_id: i64,
    json_post: Json<Post>,
    _from_local: FromLocal,
    db: &State<Database>,
) -> Json<Vec<Post>> {
    let post = json_post.0;
    if post_id != post.id {
        panic!("You're updating the wrong post!")
    }

    db_update_post(post, db).await.unwrap();

    Json(db_get_posts(false, db).await.unwrap())
}

async fn db_update_post(post: Post, db: &State<Database>) -> libsql::Result<()> {
    db.connect()?
        .execute(
            "update posts set path=?2, publish_unix_time=?3, title=?4, author=?5, tags=?6, preview=?7 where id=?1",
            (post.id, &*post.path, post.publish_time, post.title, post.author, post.tags, post.preview),
        )
        .await?;

    Ok(())
}

#[delete("/admin/post/<post_id>")]
pub async fn delete_post(
    post_id: i64,
    _from_local: FromLocal,
    db: &State<Database>,
) -> Accepted<String> {
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

        test_create_post(&client).await;

        test_get_post_by_path(&client).await;

        test_post_update(&client).await;

        test_post_delete(&client).await;

        Ok(())
    }

    async fn test_create_post(client: &Client) {
        let response = client
            .post(uri!(super::create_post()))
            .json(&NewPost {
                path: "test_path".to_string(),
                author: "author".to_string(),
                title: "title".to_string(),
                preview: "preview".to_string(),
                tags: "tags".to_string(),
            })
            .remote("127.0.0.1:80".parse().unwrap())
            .dispatch()
            .await;
        assert_eq!(response.status(), Status::Ok);

        let mut posts: Vec<Post> =
            serde_json::from_str(&response.into_string().await.unwrap()).unwrap();
        posts.retain(|p| p.path == "test_path");
        let test_post = posts.get_mut(0);
        match test_post {
            Some(post) => {
                assert_eq!(post.path, "test_path");
                assert_eq!(post.author, "author");
                assert_eq!(post.title, "title");
                assert_eq!(post.preview, "preview");
                assert_eq!(post.tags, "tags");
            }
            None => panic!("Post missing!"),
        }
    }

    async fn test_get_post_by_path(client: &Client) {
        let response = client
            .get(uri!(super::get_post("test_path")))
            .remote("127.0.0.1:80".parse().unwrap())
            .dispatch()
            .await;
        assert_eq!(response.status(), Status::Ok);

        let post: Post = serde_json::from_str(&response.into_string().await.unwrap()).unwrap();
        assert_eq!("test_path", post.path);
    }

    async fn test_post_update(client: &Client) {
        let mut posts = test_admin_get(client).await;
        let test_post = posts.get_mut(0);

        match test_post {
            Some(post) => {
                post.publish_time = 2000;
                let response = client
                    .put(uri!(super::update_post(post.id)))
                    .remote("127.0.0.1:80".parse().unwrap())
                    .json(post)
                    .dispatch()
                    .await;
                assert_eq!(response.status(), Status::Ok);

                let mut posts: Vec<Post> =
                    serde_json::from_str(&response.into_string().await.unwrap()).unwrap();
                posts.retain(|p| p.path == "test_path");
                let test_post = posts.get_mut(0);
                match test_post {
                    Some(post) => {
                        assert_eq!(2000, post.publish_time);
                    }
                    None => panic!("Post missing!"),
                }
            }
            None => panic!("Post missing!"),
        }
    }

    async fn test_post_delete(client: &Client) {
        let posts = test_admin_get(client).await;
        for post in posts.iter() {
            let response = client
                .delete(uri!(super::delete_post(post.id)))
                .remote("127.0.0.1:80".parse().unwrap())
                .dispatch()
                .await;
            assert_eq!(response.status(), Status::Accepted);
            assert_eq!("true".to_string(), response.into_string().await.unwrap());
        }

        let posts = test_admin_get(client).await;
        assert_eq!(0, posts.len());
    }

    async fn test_admin_get(client: &Client) -> Vec<Post> {
        let response = client
            .get(uri!(super::get_all_posts()))
            .remote("127.0.0.1:80".parse().unwrap())
            .dispatch()
            .await;
        assert_eq!(response.status(), Status::Ok);
        let mut posts: Vec<Post> =
            serde_json::from_str(&response.into_string().await.unwrap()).unwrap();
        posts.retain(|p| p.path == "test_path");

        posts
    }
}
