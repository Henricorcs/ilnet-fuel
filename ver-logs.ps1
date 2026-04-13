# ── Logs do iLnet FuelTrack ───────────────────────────────────────
$LOG_DIR = "$PSScriptRoot\logs"

Write-Host "`n  iLnet FuelTrack — Logs" -ForegroundColor Cyan
Write-Host "  Status: $((Get-Service iLnetFuel -ErrorAction SilentlyContinue)?.Status ?? 'NAO INSTALADO')" -ForegroundColor White
Write-Host ""

foreach ($f in @("app.log","app-error.log")) {
    $path = "$LOG_DIR\$f"
    Write-Host "  ── $f ──" -ForegroundColor $(if ($f -match "error") {"Red"} else {"Green"})
    if (Test-Path $path) { Get-Content $path -Tail 30 } else { Write-Host "  (vazio)" -ForegroundColor Gray }
    Write-Host ""
}

Write-Host "  Para acompanhar ao vivo:" -ForegroundColor Gray
Write-Host "  Get-Content .\logs\app.log -Wait -Tail 20`n" -ForegroundColor Gray
