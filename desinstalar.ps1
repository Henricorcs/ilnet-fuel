# ── Remove o servico iLnet FuelTrack do Windows ──────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) { Write-Host "Execute como Administrador!" -ForegroundColor Red; pause; exit 1 }

$NSSM = "$PSScriptRoot\tools\nssm.exe"
$confirm = Read-Host "`n  Remover o servico iLnetFuel? (s/N)"
if ($confirm -notmatch "^[sS]$") { Write-Host "  Cancelado.`n"; exit 0 }

$svc = Get-Service iLnetFuel -ErrorAction SilentlyContinue
if ($svc) {
    if ($svc.Status -eq "Running") { Stop-Service iLnetFuel -Force }
    Start-Sleep -Seconds 2
    if (Test-Path $NSSM) { & $NSSM remove iLnetFuel confirm | Out-Null }
    else { sc.exe delete iLnetFuel | Out-Null }
    Write-Host "  Servico removido. Arquivos do app mantidos.`n" -ForegroundColor Green
} else {
    Write-Host "  Servico iLnetFuel nao encontrado.`n" -ForegroundColor Yellow
}
