[Unit]
Description=The Byte Station Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/oldworldboa/host/the_byte_station_server/
ExecStart=cargo run --release
User=oldworldboa
Group=oldworldboa
Restart=always

[Install]
WantedBy=multi-user.target
