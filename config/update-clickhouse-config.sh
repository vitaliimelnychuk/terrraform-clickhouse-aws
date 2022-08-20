#!/bin/bash

HOST=$1
DESTINATION=ubuntu@$HOST

scp -i  "clickhouse.pem" ./config/config.xml $DESTINATION:/tmp/clickhouse_config.xml
scp -i  "clickhouse.pem" ./config/users.xml $DESTINATION:/tmp/clickhouse_users.xml

echo "Connecting ubuntu@$HOST..."

ssh -i "clickhouse.pem" ubuntu@$HOST <<'ENDSSH'
sudo cp /tmp/clickhouse_config.xml /etc/clickhouse-server/config.xml
sudo cp /tmp/clickhouse_users.xml /etc/clickhouse-server/users.xml

sudo service clickhouse-server restart
sudo service clickhouse-server status
ENDSSH

