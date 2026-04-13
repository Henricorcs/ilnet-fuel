# CLAUDE.md — iLnet Controle de Frota

## Projeto
Sistema completo de controle de frota para a empresa **iLnet** (telecom). Cores predominantes: azul. Responsivo (mobile-first).

## Stack
- **Backend:** Node.js + Express + SQLite (sql.js) — arquivo único `server.js`
- **Frontend:** Single-page HTML (`public/index.html`) com CSS inline + JS inline + Chart.js
- **Autenticação:** PBKDF2 + tokens de sessão (24h), middleware `authMiddleware` em todas as rotas API
- **Logo:** `public/logo.png`

## Estrutura
```
ilnet-fuel/
├── server.js              # Backend completo (~300 linhas compactadas)
├── package.json           # express, sql.js, multer, cors, morgan
├── public/
│   ├── index.html         # Frontend SPA (~1300 linhas)
│   ├── logo.png           # Logo iLnet
│   └── uploads/           # Fotos de abastecimentos e manutenções
├── database/
│   └── fueltrack.db       # SQLite (criado automaticamente)
└── CLAUDE.md
```

## Banco de Dados (SQLite via sql.js)
Tabelas:
- `usuarios` — id, nome, email, login, senha_hash, senha_salt, perfil (admin/operador), ativo
- `sessoes` — token, usuario_id, expira_em
- `veiculos` — id, placa (UNIQUE), nome, marca, modelo, ano, cor, combustivel, tanque, km_ini, ativo
- `abastecimentos` — id, veiculo_id, data, combustivel, posto, litros, preco, total, hodometro, km_rodados, consumo, cheio, nota, obs
- `fotos` — id, abastecimento_id, filename
- `checklists` — id, veiculo_id, data, tipo (saida/retorno), motorista, km, destino, obs
- `checklist_itens` — id, checklist_id, item, ok, obs
- `transferencias` — id, veiculo_id, data_saida, data_retorno, motorista_saida/retorno, km_saida/retorno, destino, status (aberto/concluido)
- `manutencoes` — id, veiculo_id, data, tipo (preventiva/corretiva/revisao), descricao, oficina, valor, km_atual, proxima_km, proxima_data, status, obs
- `manutencao_fotos` — id, manutencao_id, filename
- `motoristas` — id, nome, cnh, cnh_validade, telefone, email, ativo
- `alertas` — id, veiculo_id, tipo (manutencao_data/manutencao_km/cnh), titulo, mensagem, prioridade (critica/alta/media), lido, resolvido, referencia_id
- `config` — chave/valor (empresa, responsavel, alerta_dias_antecedencia, alerta_km_antecedencia, smtp_host/port/user/pass, alerta_email)

## API Endpoints

### Auth (sem middleware)
- `POST /api/auth/login` — {login, senha} → {token, user}
- `POST /api/auth/logout` — header Authorization Bearer
- `GET /api/auth/me` — retorna user logado
- `PUT /api/auth/senha` — {senha_atual, nova_senha}

### Protegidos (authMiddleware)
- CRUD `/api/veiculos`
- CRUD `/api/abastecimentos` (com filtros: veiculo_id, combustivel, mes, busca)
- `POST /api/fotos/:abastecimento_id` — upload multipart
- `DELETE /api/fotos/:filename`
- CRUD `/api/checklists`
- CRUD `/api/transferencias`
- CRUD `/api/manutencoes` + `/api/manutencoes/:id/fotos`
- CRUD `/api/motoristas`
- CRUD `/api/alertas` + `GET /api/alertas/count` + `PUT /api/alertas/:id/lido` + `PUT /api/alertas/ler-todos` + `PUT /api/alertas/:id/resolver`
- `POST /api/alertas/verificar` — gera alertas baseado em proxima_data, proxima_km e cnh_validade
- `POST /api/alertas/enviar-email` — envia alertas pendentes por SMTP (requer nodemailer)
- `GET /api/stats` — dashboard KPIs e dados de gráficos
- `GET/POST /api/config`
- `GET /api/export/csv`

### Admin only (adminOnly middleware)
- CRUD `/api/usuarios`
- `POST /api/alertas/enviar-email`

## Frontend (SPA)
- Login screen → checkSession() no init
- Sidebar com navegação por páginas (data-page)
- Topbar com sininho de alertas (bell-btn) + menu do usuário
- Dropdown panels para alertas e user menu
- Todas as chamadas API usam `Authorization: Bearer TOKEN`
- Em 401 → doLogout() automático
- Admin-only items via CSS: `body.is-admin .nav-item.admin-only{display:flex}`
- Charts: Chart.js (bar, doughnut, line)
- Fotos: upload via FormData + drag & drop
- Alertas: polling a cada 60s via setInterval

## Login padrão
- **Usuário:** admin
- **Senha:** admin123
- Criado automaticamente no primeiro start se não existir admin

## Para rodar
```bash
npm install
npm start
# http://localhost:3000
```

## Para e-mail (opcional)
```bash
npm install nodemailer
# Configurar SMTP em Configurações > E-mail
```

## Convenções de código
- IDs gerados com `uid()` = Date.now().toString(36) + random
- Senhas: PBKDF2 com salt aleatório de 16 bytes
- Soft delete em veículos, motoristas e usuários (ativo=0)
- Hard delete em abastecimentos, checklists, transferências, manutenções
- Fotos salvas em public/uploads/ com nome timestamp-random.ext
- DB salvo em disco a cada write (saveDb())
