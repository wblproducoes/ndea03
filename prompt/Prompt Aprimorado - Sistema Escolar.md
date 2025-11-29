# Objetivo
Crie um sistema completo de registro e acompanhamento escolar em Node.js (Express) com MySQL/MariaDB, compatível com cPanel/Passenger, com UI em Bootstrap 5.3 e JavaScript puro, comunicação em tempo real via Socket.IO e importação de registros via Excel, respeitando regras de segurança (senha administrativa em variável de ambiente) e auditabilidade.

# Tecnologias e Compatibilidade
- Backend: `Node.js (Express)`, `Socket.IO`, `mysql2` (pool), `dotenv`, `multer` (upload), `xlsx` (parse Excel)
- Frontend: `Bootstrap 5.3`, `JavaScript` (ES6), `fetch()`, `Socket.IO client`
- Deploy: cPanel (Passenger), arquivo de entrada `server.js` ou `app.js`, `.env`
- Banco: MySQL/MariaDB (compatível com cPanel)

# Modelagem de Dados
- Tabela `tables`
  - `table_id` (PK, INT AUTO_INCREMENT)
  - `table_name` (VARCHAR UNIQUE)
  - `created_at` (DATETIME)
- Tabela `records`
  - `id` (PK, INT AUTO_INCREMENT)
  - `table_id` (FK -> `tables.table_id`, nullable)
  - `serie` (VARCHAR)
  - `aluno` (VARCHAR)
  - `mesa` (VARCHAR)
  - `veio` (BOOLEAN DEFAULT 0)
  - `chamado` (BOOLEAN DEFAULT 0)
  - `produtos` (TEXT)
  - `updated_at` (DATETIME)
  - `last_change_table_id` (INT, nullable)
- Tabela `changes` (auditoria)
  - `id` (PK)
  - `record_id` (FK -> `records.id`)
  - `table_id` (FK -> `tables.table_id`)
  - `field_name` (VARCHAR) — ex.: `veio`, `chamado`, `admin_action`
  - `old_value` (VARCHAR)
  - `new_value` (VARCHAR)
  - `changed_at` (DATETIME)
  - `changed_by` (VARCHAR) — IP/table id
- Tabela `roles`
  - `role_id` (PK)
  - `role_name` (VARCHAR UNIQUE) — "Administrador", "Coxia", "Apresentador"
- Tabela `admin_users`
  - `user_id` (PK)
  - `username` (VARCHAR UNIQUE)
  - `password_hash` (VARCHAR) — hash no servidor
  - `role_id` (FK -> `roles.role_id`)
  - `created_at` (DATETIME)
- Tabela `imports`
  - `import_id` (PK)
  - `version` (VARCHAR)
  - `added_at` (DATETIME)
  - `added_by` (VARCHAR) — admin username

# Regras de Negócio
- Dispositivo/tablet escolhe um nome único e função ao abrir a página; persistência local (localStorage) e validação de unicidade no servidor.
- Nome do table não muda ao recarregar; alteração só com senha administrativa.
- Ordenação das séries: Jardim II → 5º Ano (ordem fixa configurável).
- Duplo-clique alterna `veio` e `chamado` em células específicas; cada alternância registra auditoria, atualiza em tempo real e exibe indicador “alterado por”.
- Indicador “alterado por” mostra o nome do próprio table apenas para quem fez a alteração; para os demais, apresentar indicação genérica (sem revelar o nome).
- Reset geral redefine `veio`/`chamado` para `Não`, remove indicadores, exige senha, registra auditoria e atualiza todos em tempo real.

# Socket.IO (Eventos)
- `status:toggled` — payload: `{ recordId, field, newValue, tableId }`
- `records:updated` — broadcast após importações/edições
- `reset:done` — notifica reset geral
- `table:renamed` — payload: `{ tableId, newName }`
- `counters:updated` — payload: `{ serieCounters }`
- `excel:imported` — payload: `{ importId, version, total }`

# Endpoints (API)
- `POST /admin/upload-excel` — multipart (`file`), header `X-Admin-Password: <senha>`
  - Processa XLSX com colunas: `Série`, `Aluno`, `Mesa`, `Veio`, `Chamado`, `Produtos`
  - Insere/atualiza `records`, registra em `imports`, emite `excel:imported` e `records:updated`
- `POST /admin/reset` — header `X-Admin-Password`
  - Seta `veio=0`, `chamado=0`, zera `last_change_table_id`, registra auditoria, emite `reset:done`
- `POST /admin/rename-table` — header `X-Admin-Password`, body `{ tableId, newName }`
  - Renomeia com unicidade; emite `table:renamed`
- `GET /api/records?table_id=<id>` — lista registros (paginável)
- `POST /api/record/:id/toggle` — body `{ field: 'veio'|'chamado', tableId }`
  - Alterna valor, registra auditoria (`changes`), atualiza `updated_at` e `last_change_table_id`, emite `status:toggled`, atualiza contadores
- `GET /api/counters` — retorna `{ serie: { veio: n, chamado: n } }`
- `GET /api/tables` — lista `{ table_id, table_name }`
- `POST /api/table/register` — body `{ name, role }`
  - Valida unicidade, cria/retorna `table_id`, persiste no servidor
- Admin Dashboard
  - `POST /admin/login` — body `{ username, password }` → cria sessão/JWT
  - CRUD Funções: `GET/POST/PUT/DELETE /admin/roles`
  - CRUD Admins: `GET/POST/PUT/DELETE /admin/users`
  - `GET /admin/imports` — lista importações

# Frontend (UI)
- Páginas:
  - Principal: listagem por série, contadores dinâmicos, toggles por duplo-clique, indicador “alterado por”, botão Tela Cheia
  - Modal inicial: solicitar nome único do table e função; persistir em `localStorage`
  - Admin: login (usuário `admin`), gerenciamento de Funções/Admins, página de importação de Excel e auditoria
- Logo: baixar e servir localmente em `public/logo.svg` (copiar de `https://saogoncalosp.com.br/wp-content/uploads/2025/10/logo_novo_h_350x100px.svg`)
- Tela Cheia: usar Fullscreen API
- Fetch API para todas as chamadas; Socket.IO para atualizações em tempo real.

# Segurança
- Senha administrativa definida em `ADMIN_PASSWORD` (env), nunca exposta no cliente.
- Rotas críticas exigem cabeçalho `X-Admin-Password` ou sessão/JWT de admin.
- Rate limiting básico nas rotas admin; validação de entradas; CORS conforme necessidade.
- Hash de senhas de usuários admin no servidor (ex.: bcrypt), não armazenar plaintext.

# Importação Excel (Regras)
- Aceita `.xlsx` com colunas: `Série`, `Aluno`, `Mesa`, `Veio`, `Chamado`, `Produtos`.
- Normaliza `Veio`/`Chamado` para boolean: aceita `Sim/Não`, `Yes/No`, `1/0`.
- Upsert por chave composta `{ serie, aluno }` (ou `mesa` se configurado), configurável.
- Registro de versão e data em `imports`.

# Reset Geral
- Botão “RESETAR” em Admin; exige senha; executa `POST /admin/reset`.
- Auditoria na tabela `changes` com `admin_action`.

# Contadores por Série
- Backend agrega por série: `veio=true`, `chamado=true`.
- Emissão de `counters:updated` após mudanças/import/reset; UI atualiza em tempo real.

# Identificador do Table
- Ao abrir: modal com `{ nome único, função }`, persistência em `localStorage`.
- Servidor valida e retorna `table_id`; mudanças de nome só via `POST /admin/rename-table` com senha.
- Indicador de “alterado por” persiste até `Reset Geral`; visível plenamente apenas para quem alterou.

# Deploy em cPanel
- Criar App Passenger (Node.js) com entrada `server.js`.
- `package.json` com script de inicialização: `{ "start": "node server.js" }`.
- Criar banco via cPanel; configurar `.env` com:
  - `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_NAME`, `ADMIN_PASSWORD`
- Servir estáticos de `public/`; configurar Socket.IO com fallback de transporte (websocket + polling).

# Entregáveis
- Backend + frontend completos
- Scripts SQL (DDL) de criação das tabelas
- Template Excel (`template.xlsx`)
- README com instruções de deploy no cPanel
- Código limpo, modular e testável

# Critérios de Aceite
- Alternância por duplo-clique com auditoria e atualização em tempo real
- Importação Excel com upsert e notificação em tempo real
- Reset geral com senha e auditoria
- Contadores por série atualizando em tempo real
- Nome do table único, persistente, renomeável só com senha
- Admin dashboard com login e CRUD de funções/usuários
- Senha nunca exposta no cliente; uso de `ADMIN_PASSWORD` via servidor

# Padrões de Código
- Camadas: `routes/`, `controllers/`, `services/`, `db/`, `sockets/`
- Pool MySQL com `mysql2/promise`
- Validação de payloads (ex.: `express-validator` ou validação manual)
- Logs de erros no servidor; sem segredos em logs
- Timezone e `DATETIME`: usar UTC no backend; converter para local na UI

# Comandos de Commit Automático
- Comando contínuo (PowerShell): `powershell -ExecutionPolicy Bypass -File scripts/comprot.ps1 -Watch -IntervalMinutes 2`
- Commit único: `powershell -ExecutionPolicy Bypass -File scripts/comprot.ps1 -Message "progresso inicial"`
- Inicializar repositório e configurar usuário local: `powershell -ExecutionPolicy Bypass -File scripts/comprot.ps1 -Init -SetLocalUser -UserName "Auto Commit Bot" -UserEmail "bot@example.com"`
