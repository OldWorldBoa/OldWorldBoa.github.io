use rocket::{
    Request,
    http::Status,
    request::{FromRequest, Outcome},
};
use std::net::{IpAddr, Ipv4Addr, SocketAddr};

pub struct FromLocal();

#[derive(Debug)]
pub enum FromLocalError {
    WrongRemoteAddr,
}

#[rocket::async_trait]
impl<'r> FromRequest<'r> for FromLocal {
    type Error = FromLocalError;

    async fn from_request(request: &'r Request<'_>) -> Outcome<Self, Self::Error> {
        fn is_local(remote_addr: SocketAddr) -> bool {
            remote_addr.ip() == IpAddr::V4(Ipv4Addr::new(127, 0, 0, 1))
                || (remote_addr.ip() >= IpAddr::V4(Ipv4Addr::new(192, 168, 0, 0))
                    && remote_addr.ip() <= IpAddr::V4(Ipv4Addr::new(192, 168, 255, 255)))
        }

        match request.remote() {
            None => Outcome::Error((Status::BadRequest, FromLocalError::WrongRemoteAddr)),
            Some(remote) if is_local(remote) => Outcome::Success(FromLocal()),
            Some(_) => Outcome::Error((Status::BadRequest, FromLocalError::WrongRemoteAddr)),
        }
    }
}

#[cfg(test)]
mod tests {
    use libsql::Result;

    #[tokio::test]
    async fn test_crud() -> Result<()> {
        Ok(())
    }
}
