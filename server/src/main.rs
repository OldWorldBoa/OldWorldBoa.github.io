use libsql::Builder;

#[macro_use]
extern crate rocket;

mod comments;
mod launch;
mod members;
mod posts;
mod schema;
mod security;

#[get("/ping")]
async fn index() -> &'static str {
    "pong"
}

#[launch]
async fn rocket_main() -> _ {
    let db = Builder::new_local("blog.db").build().await.unwrap();
    match schema::migrate(&db).await {
        Ok(_) => println!("Database migrated."),
        Err(e) => println!("{e}"),
    }

    launch::rocket(db)
}
