# info.oldworldboa.ca /server

Built using [Rocket](https://rocket.rs/) and [turso](https://docs.turso.tech/sdk/rust/quickstart)

## Setup

1. rustup default stable

## Build and Run

1. ``` cargo build ```
2. ``` cargo run ```

## Deploy

Run ``` ./build.sh <ip> ``` where ip is the ip of the server to deploy to. This will deploy the packaged files from ``` client/package.sh ``` and ``` server/package.sh ``` to the server in the /www/
