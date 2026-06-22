# Settings User Invitation v2e — staging deep-link smoke runner
# Usage (repo root):
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts/staging/run_settings_invitation_v2e_smoke.ps1

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)

Write-Host '=== v2e infra SQL checks ===' -ForegroundColor Cyan
supabase db query --linked -f scripts/staging/settings_user_invitation_v2e_deeplink_smoke_checks.sql

Write-Host ''
Write-Host '=== v2e regression SQL (v2c base) ===' -ForegroundColor Cyan
supabase db query --linked -f scripts/staging/settings_user_invitation_v2c_smoke_checks.sql

Write-Host ''
Write-Host '=== Edge functions (tenant-invite-user-v2 expected ACTIVE) ===' -ForegroundColor Cyan
supabase functions list --project-ref dgzmybbgrofapjptjspf

Write-Host ''
Write-Host 'Done. Complete manual E2E per docs/ops/settings_user_invitation_v2e_runbook.md' -ForegroundColor Green
