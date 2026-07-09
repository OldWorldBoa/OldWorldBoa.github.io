# OldWorldBoa.github.io
Hello! This is my personal website.

## Client

Found in ./client/

 The front-end is built using the [Elm Language](elm-lang.org), [elm-pages](https://elm-pages.com/) and the [koa adapter](https://github.com/shahnhogan/elm-pages-starter-koa).

## Server

Found in ./server/

For the server portion, the elm-pages local DB wasn't working well with my IDE, so I changed to a dedicated server using Rust and Rocket.

## Deploy

Run ``` ./build.sh <ip> ``` where ip is the ip of the server to deploy to. This will deploy the packaged files from ``` client/package.sh ``` and ``` server/package.sh ``` to the server in ``` /www/byte-station-client ``` and ``` /www/byte-station-server ```, respectively
