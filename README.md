# iLnet — Controle de Frota

Sistema completo de gestão de frota para a empresa iLnet.

## Funcionalidades

### 🔐 Autenticação
- Login/senha com sessões seguras (24h)
- Perfis: Administrador e Operador
- Gestão de usuários (admin)
- Alteração de senha

### 🚗 Gestão de Frota
- Cadastro de veículos (placa, marca, modelo, ano, combustível)
- Abastecimentos com fotos de comprovante
- Controle de hodômetro e consumo automático
- Checklist de inspeção (saída/retorno)
- Transferências de veículos
- Manutenções preventivas/corretivas com fotos

### 👤 Motoristas
- Cadastro com CNH e validade
- Alertas de CNH vencendo

### 🔔 Alertas Inteligentes
- Previsão de manutenção por data
- Previsão de manutenção por km
- Alerta de CNH vencendo
- Notificações na tela (sininho)
- Envio por e-mail (SMTP configurável)
- Prioridades: crítica, alta, média

### 📊 Dashboard & Relatórios
- KPIs em tempo real
- Gráficos de gastos, consumo, preço
- Relatórios filtráveis por veículo e período
- Galeria de fotos
- Exportar CSV / Backup JSON

### 📱 Responsivo
- Interface adaptável para celular e desktop

## Instalação

```bash
npm install
npm start
```

Acesse: http://localhost:3000

**Login padrão:** admin / admin123

## Stack
- Backend: Node.js + Express + SQLite (sql.js)
- Frontend: HTML/CSS/JS + Chart.js
- Autenticação: PBKDF2 + tokens de sessão

## E-mail (opcional)
```bash
npm install nodemailer
```
Configure SMTP em Configurações > E-mail.
