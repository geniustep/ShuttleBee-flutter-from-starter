# Script to fix ClangCL toolset issue in generated vcxproj files
$buildDir = "$PSScriptRoot\..\build\windows\x64"

if (-not (Test-Path $buildDir)) {
    Write-Host "Build directory not found: $buildDir"
    exit 0
}

$vcxprojFiles = Get-ChildItem -Path $buildDir -Filter "*.vcxproj" -Recurse -ErrorAction SilentlyContinue

$fixedCount = 0
foreach ($file in $vcxprojFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    if ($content -match 'ClangCL') {
        $newContent = $content -replace '<PlatformToolset>ClangCL</PlatformToolset>', '<PlatformToolset>v143</PlatformToolset>'
        if ($newContent -ne $content) {
            [System.IO.File]::WriteAllText($file.FullName, $newContent, [System.Text.Encoding]::UTF8)
            Write-Host "Fixed: $($file.FullName)"
            $fixedCount++
        }
    }
}

if ($fixedCount -eq 0) {
    Write-Host "No files needed fixing."
}
else {
    Write-Host "Fixed $fixedCount file(s)."
}
