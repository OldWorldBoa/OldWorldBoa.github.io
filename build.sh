if [ -z "$1" ];
then
  echo "Pass in the IP of the target server"
  exit 1
fi

CLIENT_PKG=("$2")
if [ -z "$2" ];
then
  echo "Packaging client with build. Options are one of 'build', 'all', or 'static'."
  CLIENT_PKG=("build")
fi

read -s -p "Password: " password
echo ""

# Build client
cd ./client/
./package.sh "${CLIENT_PKG[@]}"
sshpass -p $password scp ./client.tar.gz oldworldboa@$1:/www/byte-station-client

# Build server
cd ../server
./package.sh
sshpass -p $password scp ./server.tar.gz oldworldboa@$1:/www/byte-station-server
sshpass -p $password scp ./byte-station-server.service oldworldboa@$1:/www/byte-station-server

# Deploy built files
sshpass -p $password ssh oldworldboa@$1 'cd /www/byte-station-client
tar -xf client.tar.gz
pm2 restart server

cd /www/byte-station-server
tar -xf server.tar.gz
sudo systemctl daemon-reload
sudo systemctl restart byte-station-server'
