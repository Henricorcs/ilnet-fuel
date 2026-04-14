# ═══════════════════════════════════════════════════════════
#  iLnet FuelTrack — Instalador Windows (sem ngrok)
#  Registra o app Node.js como Servico Windows (auto-start)
#  Execute com: PowerShell (Admin) > .\install.ps1
# ═══════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

function Write-Step($n, $msg) { Write-Host "`n  [$n] " -ForegroundColor Cyan -NoNewline; Write-Host $msg }
function Write-Ok($msg)       { Write-Host "      OK  $msg" -ForegroundColor Green }
function Write-Warn($msg)     { Write-Host "      !   $msg" -ForegroundColor Yellow }
function Write-Fail($msg)     { Write-Host "      ERR $msg" -ForegroundColor Red }

Clear-Host
Write-Host ""
Write-Host "  ══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "    iLnet FuelTrack — Instalacao Win10  " -ForegroundColor Cyan
Write-Host "  ══════════════════════════════════════" -ForegroundColor Cyan

# ── Verificar administrador ──────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) {
    Write-Fail "Abra o PowerShell como Administrador e tente novamente."
    pause; exit 1
}

$APP_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$NSSM    = "$APP_DIR\tools\nssm.exe"
$LOG_DIR = "$APP_DIR\logs"

Write-Host "`n  Pasta do app: $APP_DIR" -ForegroundColor Gray

# ── 1. Pastas ────────────────────────────────────────────────
Write-Step "1/4" "Criando pastas necessarias..."
@("$APP_DIR\database", "$APP_DIR\public\uploads", "$APP_DIR\tools", $LOG_DIR) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}
Write-Ok "Pastas ok"

# ── 2. Node.js ───────────────────────────────────────────────
Write-Step "2/4" "Verificando Node.js..."
$nodeExe = (Get-Command node -ErrorAction SilentlyContinue)?.Source
if ($nodeExe) {
    Write-Ok "Node.js $(node -v) encontrado em $nodeExe"
} else {
    Write-Warn "Node.js nao encontrado. Baixando versao LTS..."
    $msi = "$env:TEMP\node-lts.msi"
    Invoke-WebRequest "https://nodejs.org/dist/v22.11.0/node-v22.11.0-x64.msi" -OutFile $msi -UseBasicParsing
    Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /quiet /norestart" -Wait
    Remove-Item $msi -Force -ErrorAction SilentlyContinue
    # Recarregar PATH
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")
    $nodeExe = (Get-Command node -ErrorAction SilentlyContinue)?.Source
    if (-not $nodeExe) { $nodeExe = "C:\Program Files\nodejs\node.exe" }
    Write-Ok "Node.js $(& $nodeExe -v) instalado"
}

# npm install
Write-Host "      Instalando dependencias npm..." -ForegroundColor Gray
Push-Location $APP_DIR
npm install --omit=dev --silent 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Fail "Falha no npm install. Verifique a pasta do app."; Pop-Location; exit 1 }
Pop-Location
Write-Ok "Dependencias npm instaladas"

# ── 3. NSSM ──────────────────────────────────────────────────
Write-Step "3/4" "Baixando NSSM (gerenciador de servicos)..."
if (Test-Path $NSSM) {
    Write-Ok "NSSM ja presente"
} else {
    $zip = "$env:TEMP\nssm.zip"
    Invoke-WebRequest "https://nssm.cc/release/nssm-2.24.zip" -OutFile $zip -UseBasicParsing
    Expand-Archive $zip -DestinationPath "$env:TEMP\nssm_ext" -Force
    $exe = Get-ChildItem "$env:TEMP\nssm_ext" -Recurse -Filter "nssm.exe" |
           Where-Object { $_.Directory -match "win64" } |
           Select-Object -First 1
    if (-not $exe) {
        $exe = Get-ChildItem "$env:TEMP\nssm_ext" -Recurse -Filter "nssm.exe" | Select-Object -First 1
    }
    Copy-Item $exe.FullName -Destination $NSSM -Force
    Remove-Item $zip, "$env:TEMP\nssm_ext" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Ok "NSSM pronto"
}

# ── 4. Servico Windows ────────────────────────────────────────
Write-Step "4/4" "Registrando servico Windows iLnetFuel..."

# Remove servico anterior se existir
$svc = Get-Service -Name "iLnetFuel" -ErrorAction SilentlyContinue
if ($svc) {
    Write-Warn "Servico anterior encontrado, removendo..."
    if ($svc.Status -eq "Running") { Stop-Service iLnetFuel -Force }
    Start-Sleep -Seconds 2
    & $NSSM remove iLnetFuel confirm | Out-Null
    Start-Sleep -Seconds 2
}

# Criar servico
& $NSSM install  iLnetFuel "$nodeExe"
& $NSSM set      iLnetFuel AppDirectory    "$APP_DIR"
& $NSSM set      iLnetFuel AppParameters   "server.js"
& $NSSM set      iLnetFuel DisplayName     "iLnet FuelTrack"
& $NSSM set      iLnetFuel Description     "Sistema de Controle de Abastecimento iLnet"
& $NSSM set      iLnetFuel Start           SERVICE_AUTO_START
& $NSSM set      iLnetFuel ObjectName      LocalSystem
& $NSSM set      iLnetFuel AppStdout       "$LOG_DIR\app.log"
& $NSSM set      iLnetFuel AppStderr       "$LOG_DIR\app-error.log"
& $NSSM set      iLnetFuel AppRotateFiles  1
& $NSSM set      iLnetFuel AppRotateBytes  5242880       # 5 MB por arquivo
& $NSSM set      iLnetFuel AppRestartDelay 5000
& $NSSM set      iLnetFuel AppEnvironmentExtra "PORT=3000" "NODE_ENV=production"

Write-Ok "Servico criado (inicio automatico com o Windows)"

# Iniciar agora
Write-Host "      Iniciando servico..." -ForegroundColor Gray
Start-Service iLnetFuel
Start-Sleep -Seconds 3

$status = (Get-Service iLnetFuel).Status
Write-Ok "Status: $status"

# ── Resultado ─────────────────────────────────────────────────
Write-Host ""
Write-Host "  ══════════════════════════════════════" -ForegroundColor Green
Write-Host "    Instalacao concluida!               " -ForegroundColor Green
Write-Host "  ══════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "  App rodando em: http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Outros scripts disponiveis:" -ForegroundColor White
Write-Host "    .\reiniciar.ps1     reinicia o servico" -ForegroundColor Gray
Write-Host "    .\ver-logs.ps1      mostra os logs do app" -ForegroundColor Gray
Write-Host "    .\desinstalar.ps1   remove o servico" -ForegroundColor Gray
Write-Host ""
Write-Host "  Ou gerencie via: Win+R > services.msc > iLnet FuelTrack" -ForegroundColor Gray
Write-Host ""
