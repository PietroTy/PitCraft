#!/bin/bash

# --- Configurações ---
CONFIG_FILE="config.json"
INSTANCES_DIR="instances"
PLAYIT_LOG="playit_log.txt"

# --- Funções ---

# Função para listar instâncias
list_instances() {
    echo "Instâncias disponíveis em $INSTANCES_DIR/:"
    ls "$INSTANCES_DIR"
    ACTIVE=$(jq -r '.active_instance' "$CONFIG_FILE")
    echo "---------------------------"
    echo "Instância ATIVA: $ACTIVE"
}

# Função para trocar a instância ativa
switch_instance() {
    local NAME=$1
    if [ -d "$INSTANCES_DIR/$NAME" ]; then
        # Atualiza o config.json usando jq
        jq ".active_instance = \"$NAME\"" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        echo "Trocado para a instância: $NAME"
    else
        echo "Erro: Instância '$NAME' não encontrada."
    fi
}

# Função para atualizar a instância vanilla para a última versão do Minecraft
update_vanilla() {
    echo "Buscando a versão mais recente do Minecraft..."
    local MC_VERSION=$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r '.latest.release')
    echo "Versão detectada: $MC_VERSION"

    echo "Buscando o Loader mais recente do Fabric..."
    local LOADER_VERSION=$(curl -s https://meta.fabricmc.net/v2/versions/loader | jq -r '.[] | select(.stable == true) | .version' | head -n 1)
    echo "Loader detectado: $LOADER_VERSION"

    echo "Buscando o Installer mais recente do Fabric..."
    local INSTALLER_VERSION=$(curl -s https://meta.fabricmc.net/v2/versions/installer | jq -r '.[] | select(.stable == true) | .version' | head -n 1)
    echo "Installer detectado: $INSTALLER_VERSION"

    local DOWNLOAD_URL="https://meta.fabricmc.net/v2/versions/loader/$MC_VERSION/$LOADER_VERSION/$INSTALLER_VERSION/server/jar"
    local TARGET_DIR="$INSTANCES_DIR/vanilla"
    local TARGET_FILE="$TARGET_DIR/fabric-server-launch.jar"

    echo "Baixando Fabric Server ($MC_VERSION)..."
    mkdir -p "$TARGET_DIR"
    curl -L -o "$TARGET_FILE" "$DOWNLOAD_URL"

    if [ $? -eq 0 ]; then
        echo "Sucesso! Instância vanilla atualizada para $MC_VERSION com Fabric loader $LOADER_VERSION."
    else
        echo "Erro ao baixar a atualização."
    fi
}

# Função para configurar a instância (EULA, Properties, OP, SEED)
setup_instance() {
    local INSTANCE=$1
    local DESCRIPTION=$2
    local SEED=$3
    local DIR="$INSTANCES_DIR/$INSTANCE"

    echo "Configurando padrões para $INSTANCE..."

    # 1. Aceitar EULA
    echo "eula=true" > "$DIR/eula.txt"

    # 2. Configurar server.properties (Nome do mundo, MOTD e SEED)
    if [ -f "$DIR/server.properties" ]; then
        # Garante que as propriedades existam ou as atualiza
        if grep -q "^level-name=" "$DIR/server.properties"; then
            sed -i "s/^level-name=.*/level-name=PitCraft/" "$DIR/server.properties"
        else
            echo "level-name=PitCraft" >> "$DIR/server.properties"
        fi

        if grep -q "^motd=" "$DIR/server.properties"; then
            sed -i "s/^motd=.*/motd=PitCraft - $DESCRIPTION/" "$DIR/server.properties"
        else
            echo "motd=PitCraft - $DESCRIPTION" >> "$DIR/server.properties"
        fi

        # Configura a SEED se estiver definida no config.json
        if [ "$SEED" != "null" ] && [ "$SEED" != "" ]; then
            if grep -q "^level-seed=" "$DIR/server.properties"; then
                sed -i "s/^level-seed=.*/level-seed=$SEED/" "$DIR/server.properties"
            else
                echo "level-seed=$SEED" >> "$DIR/server.properties"
            fi
        fi
    else
        cat <<EOF > "$DIR/server.properties"
level-name=PitCraft
motd=PitCraft - $DESCRIPTION
EOF
        if [ "$SEED" != "null" ] && [ "$SEED" != "" ]; then
            echo "level-seed=$SEED" >> "$DIR/server.properties"
        fi
    fi

    # 3. Definir TyREXy_ como OP
    echo "TyREXy_" > "$DIR/ops.txt"
    cat <<EOF > "$DIR/ops.json"
[
  {
    "uuid": "4890c008-8cc4-3866-ab5d-c6974fed7906",
    "name": "TyREXy_",
    "level": 4,
    "bypassesPlayerLimit": false
  }
]
EOF
}

# Função para iniciar o servidor
start_server() {
    # 1. Carregar configurações da instância ativa
    ACTIVE=$(jq -r '.active_instance' "$CONFIG_FILE")
    
    # Extrair valores do config.json usando jq
    JAVA_PATH=$(jq -r ".instances.\"$ACTIVE\".java_path" "$CONFIG_FILE")
    JAR_FILE=$(jq -r ".instances.\"$ACTIVE\".jar_file" "$CONFIG_FILE")
    ARGS=$(jq -r ".instances.\"$ACTIVE\".args" "$CONFIG_FILE")
    DESCRIPTION=$(jq -r ".instances.\"$ACTIVE\".description" "$CONFIG_FILE")
    SEED=$(jq -r ".instances.\"$ACTIVE\".seed" "$CONFIG_FILE")

    if [ "$JAVA_PATH" == "null" ] || [ "$JAR_FILE" == "null" ]; then
        echo "Erro ao carregar configurações para '$ACTIVE'."
        exit 1
    fi

    # 2. Rodar setup automatizado
    setup_instance "$ACTIVE" "$DESCRIPTION" "$SEED"

    # 3. Rodar backup automático antes de ligar
    backup_instance "$ACTIVE"

    echo "Subindo Hub PitCraft..."
    echo "Instância: $ACTIVE"

    # 3. Iniciar Playit se necessário
    if ! pgrep -x "playit" > /dev/null; then
        echo "Iniciando Playit em segundo plano..."
        playit < /dev/null > "$PLAYIT_LOG" 2>&1 &
        disown
    fi

    # 4. Rodar o servidor
    cd "$INSTANCES_DIR/$ACTIVE" || exit
    
    echo "Iniciando Java..."

    # Garante que o terminal mostre o que o usuário digita
    stty echo

    # Roda o servidor limpando a saída:
    # - Remove sequências ANSI de posicionamento/cor (causa da bagunça)
    # - Remove caracteres \r
    "$JAVA_PATH" $ARGS \
        -Djline.terminal=jline.UnsupportedTerminal \
        -Dfml.queryResult=confirm \
        -jar "$JAR_FILE" nogui 2>&1 | stdbuf -oL sed 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/\r//g'
}

# Função para realizar backup do mundo (Diário e Semanal)
backup_instance() {
    local INSTANCE=$1
    local BACKUPS_DIR="backups"
    local WORLD_DIR="$INSTANCES_DIR/$INSTANCE/PitCraft"
    local DATE=$(date +%Y-%m-%d)
    local DAY_OF_WEEK=$(date +%u) # 1-7, 7 é Domingo

    mkdir -p "$BACKUPS_DIR"

    if [ ! -d "$WORLD_DIR" ]; then
        # Tenta procurar pela pasta padrão 'world' caso PitCraft não exista ainda
        if [ -d "$INSTANCES_DIR/$INSTANCE/world" ]; then
            WORLD_DIR="$INSTANCES_DIR/$INSTANCE/world"
        else
            echo "Aviso: Pasta do mundo não encontrada em $INSTANCE. Pulando backup."
            return
        fi
    fi

    echo "Iniciando backup para a instância: $INSTANCE..."

    # 1. Backup Diário (sobrescreve o daily anterior da mesma instância)
    local DAILY_FILE="$BACKUPS_DIR/${INSTANCE}_daily.tar.gz"
    echo "Gerando backup diário ($DAILY_FILE)..."
    tar -czf "$DAILY_FILE" -C "$(dirname "$WORLD_DIR")" "$(basename "$WORLD_DIR")"

    # 2. Backup Semanal (Ocorre na Terça-feira ou se solicitado via comando)
    # Toda semana o daily atual vira o weekly (sobrescrevendo o anterior)
    if [ "$DAY_OF_WEEK" -eq 2 ]; then
        local WEEKLY_FILE="$BACKUPS_DIR/${INSTANCE}_weekly.tar.gz"
        echo "Hoje é Domingo! Atualizando backup semanal ($WEEKLY_FILE)..."
        cp "$DAILY_FILE" "$WEEKLY_FILE"
    fi

    echo "Backup concluído com sucesso."
}

# --- Main ---

case "$1" in
    list)
        list_instances
        ;;
    switch)
        switch_instance "$2"
        ;;
    start)
        start_server
        ;;
    update)
        update_vanilla
        ;;
    backup)
        ACTIVE=$(jq -r '.active_instance' "$CONFIG_FILE")
        backup_instance "$ACTIVE"
        ;;
    *)
        echo "Uso: $0 {list|switch <nome>|start|update|backup}"
        exit 1
        ;;
esac
