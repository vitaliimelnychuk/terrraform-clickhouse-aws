#!/bin/bash

HOST=$1

echo "Connecting ubuntu@$HOST..."

ssh -i "clickhouse.pem" ubuntu@$HOST <<'ENDSSH'
echo "deb http://repo.yandex.ru/clickhouse/deb/stable/ main/" | sudo tee /etc/apt/sources.list.d/clickhouse.list
sudo apt-get update
sudo apt-get install -y clickhouse-server clickhouse-client
sudo service clickhouse-server start
sudo service clickhouse-server status
ENDSSH
