#!/usr/bin/env pwsh

# ════════════════════════════════════════════════════════════════════════════
# 🔧 Debug Console Fix Script
# ════════════════════════════════════════════════════════════════════════════
# Purpose: Fix frozen/stuck Debug Console in Cursor/VS Code
# Usage: .\fix_console.ps1
# ════════════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔧 Debug Console Fix Script" -ForegroundColor Yellow
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 1: Kill Flutter processes
Write-Host "Step 1/4: Stopping Flutter processes..." -ForegroundColor Cyan
$flutterProcesses = Get-Process flutter -ErrorAction SilentlyContinue
if ($flutterProcesses) {
    $flutterProcesses | Stop-Process -Force
    Write-Host "  ✅ Stopped $($flutterProcesses.Count) Flutter process(es)" -ForegroundColor Green
}
else {
    Write-Host "  ℹ️  No Flutter processes found" -ForegroundColor Gray
}
Write-Host ""

# Step 2: Clean Flutter cache
Write-Host "Step 2/4: Cleaning Flutter build cache..." -ForegroundColor Cyan
try {
    flutter clean | Out-Null
    Write-Host "  ✅ Cache cleaned successfully" -ForegroundColor Green
}
catch {
    Write-Host "  ⚠️  Warning: Could not clean cache" -ForegroundColor Yellow
}
Write-Host ""

# Step 3: Get dependencies
Write-Host "Step 3/4: Getting Flutter dependencies..." -ForegroundColor Cyan
try {
    flutter pub get | Out-Null
    Write-Host "  ✅ Dependencies fetched successfully" -ForegroundColor Green
}
catch {
    Write-Host "  ⚠️  Warning: Could not get dependencies" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Check settings
Write-Host "Step 4/4: Verifying settings..." -ForegroundColor Cyan

$settingsPath = ".vscode\settings.json"
if (Test-Path $settingsPath) {
    Write-Host "  ✅ VS Code settings found" -ForegroundColor Green
    
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
    
    # Check console history size
    if ($settings.'debug.console.historySize' -ge 10000) {
        Write-Host "  ✅ Console history size is adequate ($($settings.'debug.console.historySize'))" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠️  Console history size is low. Consider increasing to 10000" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  ℹ️  No .vscode/settings.json found (OK)" -ForegroundColor Gray
}
Write-Host ""

# Final recommendations
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Fix Complete!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Open 'lib/bootstrap/bootstrap.dart'" -ForegroundColor White
Write-Host "  2. Add this line:" -ForegroundColor White
Write-Host "     LoggerConfig.minimal();" -ForegroundColor Cyan
Write-Host "  3. Press F5 to start debugging" -ForegroundColor White
Write-Host ""
Write-Host "💡 Quick Tips:" -ForegroundColor Yellow
Write-Host "  • Press Ctrl+K in Debug Console to clear it" -ForegroundColor White
Write-Host "  • Use LoggerConfig.networkOnly() for API debugging" -ForegroundColor White
Write-Host "  • Use LoggerConfig.trackingOnly() for GPS debugging" -ForegroundColor White
Write-Host ""
Write-Host "📖 For more help, see:" -ForegroundColor Yellow
Write-Host "  • DEBUG_CONSOLE_TROUBLESHOOTING.md" -ForegroundColor White
Write-Host "  • LOGGING_QUICKSTART.md" -ForegroundColor White
Write-Host ""

# Pause before exit
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
