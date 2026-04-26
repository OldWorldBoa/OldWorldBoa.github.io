use turso::Builder;

pub async fn migrate() -> turso::Result<()> {
    create_db().await
}

async fn create_db() -> turso::Result<()> {
    let db = Builder::new_local("blog.db").build().await?;
    let conn = db.connect()?;

    // Create versioning
    conn.execute(
        r#"
        CREATE TABLE IF NOT EXISTS db_version (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            publish_unix_time INTEGER DEFAULT unixepoch
        )"#,
        (),
    )
    .await?;

    let mut exists = conn
        .query("select * from db_version where id = 1", ())
        .await?;
    if exists.next().await?.is_some() {
        return Ok(());
    }

    conn.execute(
        "insert into db_version (publish_unix_time) values (unixepoch())",
        (),
    )
    .await?;

    println!("Inserted version 1");

    // Create initial schema
    conn.execute(
        r#"
        create table if not exists posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT NOT NULL,
            publish_unix_time INTEGER DEFAULT 9223372036854775807
        )"#,
        (),
    )
    .await?;

    conn.execute(
        r#"
        create table if not exists members(
            id integer primary key autoincrement,
            name text,
            username text not null,
            email text not null,
            password text not null,
            salt text not null
        )
        "#,
        (),
    )
    .await?;

    conn.execute(
        r#"
        create table if not exists comments (
            id integer primary key autoincrement,
            member_id integer not null,
            post_id integer not null,
            commented_by text not null,
            content text not null,
            approved integer,
            commented_at integer default unixepoch,
            foreign key(member_id) references members(id),
            foreign key(post_id) references posts(id)
        )
        "#,
        (),
    )
    .await?;

    // Fill in initial data
    let posts_inserted = conn
        .execute(
            "insert into posts (path) values (?1)",
            ["blog/hello-world.md"],
        )
        .await?;

    let members_inserted = conn
        .execute(
            "insert into members (name, username, email, password, salt) values (?1, ?2, ?3, ?4, ?5)",
            ["anon", "anon", "anon", "anon", "anon"],
        )
        .await?;

    println!("Inserted {} posts", posts_inserted);
    println!("Inserted {} members", members_inserted);

    Ok(())
}
