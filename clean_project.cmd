@echo off
echo ========================================
echo   NETTOYAGE DU PROJET B-LINK
echo ========================================
echo.

echo [1/6] Suppression du dossier build...
rd /s /q build 2>nul
echo ✓ Dossier build supprimé

echo.
echo [2/6] Suppression de .dart_tool...
rd /s /q .dart_tool 2>nul
echo ✓ Dossier .dart_tool supprimé

echo.
echo [3/6] Suppression de node_modules...
rd /s /q node_modules 2>nul
echo ✓ Dossier node_modules supprimé

echo.
echo [4/6] Suppression des caches Android...
rd /s /q android\.gradle 2>nul
rd /s /q android\build 2>nul
rd /s /q android\app\build 2>nul
echo ✓ Caches Android supprimés

echo.
echo [5/6] Suppression des caches iOS...
rd /s /q ios\Pods 2>nul
rd /s /q ios\.symlinks 2>nul
del /f /q ios\Podfile.lock 2>nul
echo ✓ Caches iOS supprimés

echo.
echo [6/6] Suppression des fichiers temporaires...
del /f /q pubspec.lock 2>nul
del /f /q .flutter-plugins-dependencies 2>nul
del /f /q *.log 2>nul
del /f /q firestore-debug.log 2>nul
echo ✓ Fichiers temporaires supprimés

echo.
echo ========================================
echo   NETTOYAGE TERMINÉ !
echo ========================================
echo.
echo Votre projet est maintenant propre.
echo.
echo Prochaines étapes:
echo 1. flutter pub get
echo 2. flutter run
echo.
pause
