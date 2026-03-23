# PitCraft Hub 🕹️

Central modular de servidores Minecraft.

### Comandos Rápidos
- `./pitcraft.sh list`            - Ver servidores e qual está ativo.
- `./pitcraft.sh switch <nome>`   - Trocar servidor ativo (ex: `vanilla`).
- `./pitcraft.sh start`           - Ligar servidor + Playit com setup e backup automático.
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
