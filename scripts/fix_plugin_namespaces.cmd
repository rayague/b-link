@echo off
REM Script to auto-fix namespace issues in Flutter plugins
REM This adds the namespace declaration to plugin build.gradle files that are missing it

setlocal enabledelayedexpansion

echo [INFO] Scanning Flutter pub cache for plugins without namespace...

set PUB_CACHE=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev

REM List of known plugins that need namespace fixes (add more as needed)
set PLUGINS_TO_FIX=flutter_native_timezone-2.0.0 flutter_secure_storage-4.2.1

for %%P in (%PLUGINS_TO_FIX%) do (
    set PLUGIN_PATH=%PUB_CACHE%\%%P\android
    set BUILD_GRADLE=!PLUGIN_PATH!\build.gradle
    set MANIFEST=!PLUGIN_PATH!\src\main\AndroidManifest.xml
    
    if exist "!BUILD_GRADLE!" (
        if exist "!MANIFEST!" (
            echo [INFO] Processing %%P...
            
            REM Extract package name from AndroidManifest.xml
            for /f "tokens=2 delims==" %%A in ('findstr /C:"package=" "!MANIFEST!"') do (
                set PACKAGE_LINE=%%A
                set PACKAGE_NAME=!PACKAGE_LINE:"=!
                set PACKAGE_NAME=!PACKAGE_NAME:>=!
                set PACKAGE_NAME=!PACKAGE_NAME: =!
                
                REM Check if namespace already exists
                findstr /C:"namespace" "!BUILD_GRADLE!" >nul
                if errorlevel 1 (
                    echo [FIX] Adding namespace '!PACKAGE_NAME!' to %%P
                    
                    REM Create temp file with namespace added
                    set TEMP_FILE=%TEMP%\gradle_fix_%%P.tmp
                    (
                        for /f "usebackq delims=" %%L in ("!BUILD_GRADLE!") do (
                            set LINE=%%L
                            echo !LINE!
                            if "!LINE!"=="android {" (
                                echo     namespace '!PACKAGE_NAME!'
                            )
                        )
                    ) > "!TEMP_FILE!"
                    
                    REM Replace original file
                    move /Y "!TEMP_FILE!" "!BUILD_GRADLE!" >nul
                    echo [OK] Fixed %%P
                ) else (
                    echo [SKIP] %%P already has namespace
                )
            )
        ) else (
            echo [WARN] AndroidManifest.xml not found for %%P
        )
    ) else (
        echo [WARN] build.gradle not found for %%P
    )
)

echo.
echo [DONE] Namespace fix completed!
echo [INFO] Run 'flutter clean' then 'flutter run' to rebuild your project.
