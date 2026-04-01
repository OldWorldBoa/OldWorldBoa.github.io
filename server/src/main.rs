use crate::{comments::get_comments_by_post, posts::get_posts, users::get_user_by_id};

#[macro_use]
extern crate rocket;

mod comments;
mod posts;
mod schema;
mod security;
mod users;

#[get("/ping")]
async fn index() -> &'static str {
    "pong"
}

#[launch]
async fn rocket() -> _ {
    match schema::migrate().await {
        Ok(_) => println!("Database migrated."),
        Err(e) => println!("{}", e),
    }

    let base = "/";
    rocket::build()
        .mount(base, routes![index])
        // Comment endpoints
        .mount(base, routes![get_comments_by_post])
        // User endpoints
        .mount(base, routes![get_user_by_id])
        // Post endpoints
        .mount(base, routes![get_posts])
}
