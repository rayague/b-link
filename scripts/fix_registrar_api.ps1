# PowerShell script to fix obsolete Registrar API in Flutter plugins

$PubCache = "$env:LOCALAPPDATA\Pub\Cache\hosted\pub.dev"

Write-Host "[INFO] Fixing obsolete Registrar API in Flutter plugins..." -ForegroundColor Cyan

$fixedCount = 0

# List of known plugins with Registrar issues
$pluginsToFix = @(
    "flutter_secure_storage-4.2.1"
)

foreach ($plugin in $pluginsToFix) {
    $javaFiles = Get-ChildItem -Path "$PubCache\$plugin" -Recurse -Filter "*.java" -ErrorAction SilentlyContinue
    $ktFiles = Get-ChildItem -Path "$PubCache\$plugin" -Recurse -Filter "*.kt" -ErrorAction SilentlyContinue
    
    foreach ($file in ($javaFiles + $ktFiles)) {
        $content = Get-Content $file.FullName -Raw
        $originalContent = $content
        
        # Remove Registrar import
        $content = $content -replace 'import\s+io\.flutter\.plugin\.common\.PluginRegistry\.Registrar;\s*\r?\n', ''
        
        # Remove registerWith method (Java version)
        $content = $content -replace '(?s)@SuppressWarnings\("deprecation"\)\s*public\s+static\s+void\s+registerWith\s*\([^)]*\)\s*\{[^}]*\}', ''
        $content = $content -replace '(?s)public\s+static\s+void\s+registerWith\s*\([^)]*\)\s*\{[^}]*\}', ''
        
        # Remove registerWith method (Kotlin version)
        $content = $content -replace '(?s)companion\s+object\s*\{[^}]*fun\s+registerWith[^}]*\}', ''
        
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            Write-Host "[FIXED] $($file.FullName)" -ForegroundColor Green
            $fixedCount++
        }
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Fixed $fixedCount files" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
