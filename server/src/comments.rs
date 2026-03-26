pub struct Comment {
    /*
        *            id integer primary key autoincrement,
                user_id integer not null,
                post_id integer not null,
                content text not null,
                approved integer,
                commented_at integer default unixepoch,
                foreign key(user_id) references users(id),
                foreign key(post_id) references posts(id)

    * */
    id: i32,
    userId: i32,
    postId: i32,
    content: str,
    approved: i32,
}
