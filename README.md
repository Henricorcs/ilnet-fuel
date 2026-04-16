# iLnet - Controle de Frota

Sistema web de controle de frota para a iLnet, com foco em operação diária, abastecimentos, checklists, transferências, manutenções e alertas.

## Destaques

- Dashboard com KPIs, gráficos e atalhos operacionais.
- Cadastro de veículos, motoristas e usuários.
- Abastecimentos com fotos, consumo calculado e exportação CSV.
- Checklists de saída e retorno com observações e fotos por item.
- Transferências com controle de saída, retorno e quilometragem.
- Manutenções com fotos, custos e alertas por data ou km.
- Alertas de manutenção e CNH com painel no topo e envio por e-mail.
- Interface responsiva em uma SPA única (`public/index.html`).

## Stack

- Backend: Node.js + Express + SQLite via `sql.js`
- Frontend: HTML + CSS + JavaScript inline + Chart.js
- Auth: PBKDF2 + tokens de sessão
- Uploads: `multer`
- Segurança: `helmet`, validação de senha, limpeza de sessão e rate limiting no login

## Estrutura

```text
ilnet-fuel/
|- server.js
|- package.json
|- public/
|  |- index.html
|  |- logo.png
|  `- uploads/
|- database/
|  `- fueltrack.db
|- CLAUDE.md
`- README.md
```

## Como rodar

```bash
npm install
npm start
```

Acesse [http://localhost:3000](http://localhost:3000).

## Login inicial

- Usuario: `admin`
- Senha: gerada automaticamente no primeiro start
- A senha temporária aparece no console do servidor

## Configurações úteis

- Alertas por antecedência em dias
- Alertas por km para carro
- Alertas por km para moto
- SMTP para envio de alertas por e-mail

## Observações

- O banco SQLite é salvo em `database/fueltrack.db`.
- Fotos ficam em `public/uploads/`.
- Veículos, motoristas e usuários usam desativação lógica.
- Abastecimentos, checklists, transferências e manutenções usam exclusão física.
