# Script to clean CMake cache files before rebuilding
# This script removes CMakeCache.txt and CMakeFiles directory

$buildDir = "build\windows\x64"

if (Test-Path "$buildDir\CMakeCache.txt") {
    Remove-Item "$buildDir\CMakeCache.txt" -Force
    Write-Host "✓ Deleted CMakeCache.txt" -ForegroundColor Green
} else {
    Write-Host "CMakeCache.txt not found" -ForegroundColor Yellow
}

if (Test-Path "$buildDir\CMakeFiles") {
    Remove-Item "$buildDir\CMakeFiles" -Recurse -Force
    Write-Host "✓ Deleted CMakeFiles directory" -ForegroundColor Green
} else {
    Write-Host "CMakeFiles directory not found" -ForegroundColor Yellow
}

Write-Host "`nCMake cache cleaned successfully!" -ForegroundColor Green
Write-Host "You can now rebuild the project." -ForegroundColor Cyan
