# Build client
cd ./client/
npm run build
cp -r ./* ~/host/info_oldworldboa_ca/
pm2 restart server
cd ../

# Build server
cd ./server/
cargo build --release
