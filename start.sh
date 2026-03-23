#!/bin/bash
while true
do
  /usr/lib/jvm/java-8-openjdk-amd64/bin/java -Xmx12G -Xms4G -jar forge-1.7.10-10.13.4.1614-1.7.10-universal.jar nogui
  echo "Reiniciando em 5 segundos..."
  sleep 5
done