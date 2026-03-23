#!/bin/bash

# Inicia o playit em segundo plano e joga os logs dele para um arquivo separado
playit > playit_log.txt 2>&1 &
echo "O Playit foi iniciado em segundo plano. Log em: playit_log.txt"

# Loop do Servidor de Minecraft
while true
do
  # Usando o caminho direto do Java 8 para evitar erros com outras versões
  /usr/lib/jvm/java-8-openjdk-amd64/bin/java -Xmx8G -Xms4G -jar forge-1.7.10-10.13.4.1614-1.7.10-universal.jar nogui
  echo "Servidor reiniciando em 5 segundos... Pressione Ctrl+C para parar o loop."
  sleep 5
done