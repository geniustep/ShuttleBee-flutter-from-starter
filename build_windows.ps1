# Wrapper script to build Windows app and fix ClangCL toolset issue
param(
    [string]$Mode = "debug"
)

Write-Host "Building Flutter Windows app ($Mode)..." -ForegroundColor Cyan

# Step 1: Run flutter build (will fail with ClangCL error, but generates files)
Write-Host "Step 1: Generating build files (may show ClangCL error)..." -ForegroundColor Yellow
$buildOutput = ""
if ($Mode -eq "release") {
    flutter build windows --release 2>&1 | ForEach-Object { $buildOutput += $_; Write-Host $_ }
}
else {
    flutter build windows --debug 2>&1 | ForEach-Object { $buildOutput += $_; Write-Host $_ }
}

# Step 2: Always fix ClangCL toolset issue (even if build succeeded)
Write-Host "`nStep 2: Fixing ClangCL toolset issue..." -ForegroundColor Yellow
& "$PSScriptRoot\windows\fix_toolset.ps1"

# Step 3: If build failed due to ClangCL, retry
if ($buildOutput -match "ClangCL" -or $LASTEXITCODE -ne 0) {
    Write-Host "Step 3: Retrying build after fixing toolset..." -ForegroundColor Yellow
    if ($Mode -eq "release") {
        flutter build windows --release
    }
    else {
        flutter build windows --debug
    }
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild completed successfully!" -ForegroundColor Green
}
else {
    Write-Host "`nBuild failed. Please check the errors above." -ForegroundColor Red
    exit $LASTEXITCODE
}# Wrapper script to build Windows app and fix ClangCL toolset issue
param(
    [string]$Mode = "debug"
)

Write-Host "Building Flutter Windows app ($Mode)..." -ForegroundColor Cyan

# Step 1: Run flutter build (will fail with ClangCL error, but generates files)
Write-Host "Step 1: Generating build files (may show ClangCL error)..." -ForegroundColor Yellow
$buildOutput = ""
if ($Mode -eq "release") {
    flutter build windows --release 2>&1 | ForEach-Object { $buildOutput += $_; Write-Host $_ }
}
else {
    flutter build windows --debug 2>&1 | ForEach-Object { $buildOutput += $_; Write-Host $_ }
}

# Step 2: Always fix ClangCL toolset issue (even if build succeeded)
Write-Host "`nStep 2: Fixing ClangCL toolset issue..." -ForegroundColor Yellow
& "$PSScriptRoot\windows\fix_toolset.ps1"

# Step 3: If build failed due to ClangCL, retry
if ($buildOutput -match "ClangCL" -or $LASTEXITCODE -ne 0) {
    Write-Host "Step 3: Retrying build after fixing toolset..." -ForegroundColor Yellow
    if ($Mode -eq "release") {
        flutter build windows --release
    }
    else {
        flutter build windows --debug
    }
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild completed successfully!" -ForegroundColor Green
}
else {
    Write-Host "`nBuild failed. Please check the errors above." -ForegroundColor Red
}# Wrapper script to build Windows app and fix ClangCL toolset issue
param(
    [string]$Mode = "debug"
)

Write-Host "Building Flutter Windows app ($Mode)..." -ForegroundColor Cyan

# Step 1: Run flutter build (will fail with ClangCL error, but generates files)
Write-Host "Step 1: Generating build files (may show ClangCL error)..." -ForegroundColor Yellow
$buildOutput = ""
if ($Mode -eq "release") {
    flutter build windows --release 2>&1 | ForEach-Object { $buildOutput += $_; Write-Host $_ }
}
else {
    flutter build windows --debug 2>&1 | ForEach-Object { $buildOutput += $_; Write-Host $_ }
}

# Step 2: Always fix ClangCL toolset issue (even if build succeeded)
Write-Host "`nStep 2: Fixing ClangCL toolset issue..." -ForegroundColor Yellow
& "$PSScriptRoot\windows\fix_toolset.ps1"

# Step 3: If build failed due to ClangCL, retry
if ($buildOutput -match "ClangCL" -or $LASTEXITCODE -ne 0) {
    Write-Host "Step 3: Retrying build after fixing toolset..." -ForegroundColor Yellow
    if ($Mode -eq "release") {
        flutter build windows --release
    }
    else {
        flutter build windows --debug
    }
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild completed successfully!" -ForegroundColor Green
}
else {
    Write-Host "`nBuild failed. Please check the errors above." -ForegroundColor Red
}
# Wrapper script to build Windows app and fix ClangCL toolset issue
param(
    [string]$Mode = "debug"
)

Write-Host "Building Flutter Windows app ($Mode)..." -ForegroundColor Cyan

# Step 1: Run flutter build (will fail with ClangCL error, but generates files)
Write-Host "Step 1: Generating build files (may show ClangCL error)..." -ForegroundColor Yellow
$buildOutput = ""
if ($Mode -eq "release") {
    flutter build windows --release 2>&1 | ForEach-Object { $buildOutput += $_; Write-Host $_ }
}
else {
    flutter build windows --debug 2>&1 | ForEach-Object { $buildOutput += $_; Write-Host $_ }
}

# Step 2: Always fix ClangCL toolset issue (even if build succeeded)
Write-Host "`nStep 2: Fixing ClangCL toolset issue..." -ForegroundColor Yellow
& "$PSScriptRoot\windows\fix_toolset.ps1"

# Step 3: If build failed due to ClangCL, retry
if ($buildOutput -match "ClangCL" -or $LASTEXITCODE -ne 0) {
    Write-Host "Step 3: Retrying build after fixing toolset..." -ForegroundColor Yellow
    if ($Mode -eq "release") {
        flutter build windows --release
    }
    else {
        flutter build windows --debug
    }
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild completed successfully!" -ForegroundColor Green
}
else {
    Write-Host "`nBuild failed. Please check the errors above." -ForegroundColor Red
