# PitCraft Hub 🕹️

Central modular de servidores Minecraft.

### Comandos Rápidos
- `./pitcraft.sh list`            - Ver servidores e qual está ativo.
- `./pitcraft.sh switch <nome>`   - Trocar servidor ativo (ex: `vanilla`).
- `./pitcraft.sh start`           - Ligar servidor + atualizador DuckDNS com setup e backup automático.
- `./pitcraft.sh update`          - Atualiza a instância vanilla para a última versão estável.
- `./pitcraft.sh backup`          - Força a criação de um backup diário da instância ativa.

### Automação & Padrões
O Hub configura automaticamente ao iniciar qualquer instância:
- **EULA**: Aceita no primeiro boot.
- **Mundo**: Nomeado sempre como `PitCraft`.
- **MOTD**: Descrição dinâmica da temporada ativa.
- **OP**: Usuário `TyREXy_` definido como operador padrão.
- **Seed**: Possibilidade de definir a `seed` no `config.json`.
- **RAM**: Padronizado em **8GB** com flags `G1GC` para máxima performance.

### Instâncias Disponíveis
- **orespawn**: Forge 1.7.10 + OreSpawn
- **vanilla**: Fabric (Sempre na última versão do Mine)
- **aether**: Forge 1.12.2 + Aether

### Pastas de Mods
- `instances/[instancia]/mods/`

### Rede e DDNS (DuckDNS)
A infraestrutura de túneis via Playit foi descontinuada para garantir máxima estabilidade e ping perfeito. O sistema agora exige liberação de portas (Port Forwarding) no roteador principal:
- **`13377` TCP:** Porta forçada do Servidor Minecraft base.
- **`13377` UDP:** Comunicação otimizada para o Gliby's Voice Chat.

Dentro do script principal, o DuckDNS pinga ativamente em loop (a cada 5min) para atualizar seu IP dinâmico com o seu prefixo de domínio **`[SEUDOMINIO].duckdns.org`** de forma invisível.

**Setup do Ambiente:**
Para executar o atualizador automático do domínio, você deverá criar um arquivo `.env` na raiz do projeto (como o exemplo em `.env.example`) contendo suas chaves do DuckDNS:
```
DUCKDNS_DOMAIN="meuservidor"
DUCKDNS_TOKEN="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```
