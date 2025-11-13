# PowerShell script to auto-fix namespace issues in ALL Flutter plugins
# Scans the entire pub cache and adds namespace where missing

$PubCache = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev"

Write-Host "[INFO] Scanning all Flutter plugins in pub cache for missing namespaces..." -ForegroundColor Cyan

if (!(Test-Path $PubCache)) {
    Write-Host "[ERROR] Pub cache not found at: $PubCache" -ForegroundColor Red
    exit 1
}

$fixedCount = 0
$skippedCount = 0
$errorCount = 0

Get-ChildItem -Path $PubCache -Directory | ForEach-Object {
    $pluginDir = $_.FullName
    $pluginName = $_.Name
    $buildGradle = Join-Path $pluginDir "android\build.gradle"
    $manifest = Join-Path $pluginDir "android\src\main\AndroidManifest.xml"
    
    # Only process if both files exist
    if ((Test-Path $buildGradle) -and (Test-Path $manifest)) {
        $gradleContent = Get-Content $buildGradle -Raw
        
        # Check if namespace already exists
        if ($gradleContent -match 'namespace\s+[''"]') {
            $skippedCount++
            return
        }
        
        # Extract package name from AndroidManifest.xml
        $manifestContent = Get-Content $manifest -Raw
        if ($manifestContent -match 'package="([^"]+)"') {
            $packageName = $Matches[1]
            
            Write-Host "[FIX] $pluginName - Adding namespace '$packageName'" -ForegroundColor Yellow
            
            # Add namespace after "android {" line
            $gradleContent = $gradleContent -replace '(?m)^(android\s*\{)\s*$', "`$1`r`n    namespace '$packageName'"
            
            try {
                Set-Content -Path $buildGradle -Value $gradleContent -NoNewline
                $fixedCount++
                Write-Host "[OK] $pluginName - Fixed!" -ForegroundColor Green
            } catch {
                Write-Host "[ERROR] $pluginName - Failed to write file: $_" -ForegroundColor Red
                $errorCount++
            }
        }
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SUMMARY:" -ForegroundColor Cyan
Write-Host "  Fixed:   $fixedCount plugins" -ForegroundColor Green
Write-Host "  Skipped: $skippedCount plugins (already have namespace)" -ForegroundColor Gray
Write-Host "  Errors:  $errorCount plugins" -ForegroundColor Red
Write-Host "========================================`n" -ForegroundColor Cyan

if ($fixedCount -gt 0) {
    Write-Host "[INFO] Run 'flutter clean' then rebuild your project." -ForegroundColor Cyan
}
