# ⛽ iLnet FuelTrack — Controle de Abastecimento

Sistema completo de controle de abastecimento de veículos com banco de dados SQLite.

## 🚀 Instalação

```bash
# 1. Instalar dependências
npm install

# 2. Iniciar o servidor
npm start
```

O servidor sobe em: **http://localhost:3000**

## 🌐 Usando com ngrok

```bash
# Em um terminal — rodar o servidor
npm start

# Em outro terminal — expor com ngrok
ngrok http 3000
```

Copie a URL HTTPS gerada pelo ngrok e acesse de qualquer lugar!

## 📁 Estrutura

```
ilnet-fuel/
├── server.js           ← Backend Node.js + Express
├── package.json
├── database/
│   └── fueltrack.db    ← Banco SQLite (criado automaticamente)
└── public/
    ├── index.html      ← Frontend
    └── uploads/        ← Fotos dos comprovantes
```

## 🗄️ Banco de Dados

- **SQLite** via `better-sqlite3`
- Arquivo em `database/fueltrack.db`
- Backup automático via interface web

## 📡 API REST

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | /api/veiculos | Listar veículos |
| POST | /api/veiculos | Criar veículo |
| PUT | /api/veiculos/:id | Editar veículo |
| DELETE | /api/veiculos/:id | Remover veículo |
| GET | /api/abastecimentos | Listar abastecimentos |
| POST | /api/abastecimentos | Criar abastecimento |
| PUT | /api/abastecimentos/:id | Editar abastecimento |
| DELETE | /api/abastecimentos/:id | Remover abastecimento |
| POST | /api/fotos/:id | Upload de fotos |
| DELETE | /api/fotos/:filename | Remover foto |
| GET | /api/stats | Estatísticas/dashboard |
| GET | /api/config | Configurações |
| POST | /api/config | Salvar configurações |
| GET | /api/export/csv | Exportar CSV |

## ✨ Funcionalidades

- Dashboard com gráficos (Chart.js)
- Registro completo de abastecimentos
- Upload de fotos dos comprovantes
- Cálculo automático de consumo (km/L)
- Gestão de frota (veículos)
- Relatórios por período e veículo
- Galeria de fotos
- Exportação CSV e backup JSON
- Tema iLnet (azul escuro)
