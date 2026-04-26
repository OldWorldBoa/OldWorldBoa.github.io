use crate::{
    comments::{create_comment, get_comments_by_post},
    members::get_member_by_id,
    posts::{create_post, get_posts, update_post},
};

#[macro_use]
extern crate rocket;

mod comments;
mod members;
mod posts;
mod schema;
mod security;

#[get("/ping")]
async fn index() -> &'static str {
    "pong"
}

#[launch]
async fn rocket() -> _ {
    match schema::migrate().await {
        Ok(_) => println!("Database migrated."),
        Err(e) => println!("{e}"),
    }

    let base = "/";
    rocket::build()
        .mount(base, routes![index])
        .mount(base, routes![get_comments_by_post, create_comment])
        .mount(base, routes![get_member_by_id])
        .mount(base, routes![get_posts, create_post, update_post])
}
