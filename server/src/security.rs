use rocket::{request::FromRequest, request::Outcome, Request};

struct ApiKey<'r>(&'r str);

#[derive(Debug)]
enum AuthError {
    Unauthorized,
    TokenMissing,
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for ApiKey<'r> {
    type Error = AuthError;

    async fn from_request(request: &'r Request<'_>) -> Outcome<Self, Self::Error> {
        todo!()
    }
}
