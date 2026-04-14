# ── Reinicia o servico iLnet FuelTrack ───────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) { Write-Host "Execute como Administrador!" -ForegroundColor Red; pause; exit 1 }

Write-Host "`n  Reiniciando iLnet FuelTrack..." -ForegroundColor Cyan
Restart-Service iLnetFuel -Force
Start-Sleep -Seconds 3
$status = (Get-Service iLnetFuel).Status
Write-Host "  Status: $status" -ForegroundColor $(if ($status -eq "Running") {"Green"} else {"Red"})
Write-Host "  http://localhost:3000`n" -ForegroundColor Gray
