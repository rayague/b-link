@echo off
REM Deploie les regles Firestore et les Cloud Functions en production.
REM Les tests des regles (emulateur, JDK 21+) doivent passer avant tout deploiement.
REM Usage : scripts\deploy_prod.cmd PROJECT_ID
setlocal
set PROJECT_ID=%1
if "%PROJECT_ID%"=="" (
  echo Usage: %0 PROJECT_ID
  exit /b 2
)
cd /d "%~dp0.."
where firebase >nul 2>&1 || (
  echo firebase CLI introuvable : npm install -g firebase-tools
  exit /b 2
)
echo Les Cloud Functions exigent le forfait Blaze sur %PROJECT_ID%.
set /p CONT="Blaze est-il active sur %PROJECT_ID% ? (y/N) "
if /i not "%CONT%"=="y" (
  echo Activez Blaze puis relancez. Abandon.
  exit /b 3
)
echo Tests des regles Firestore...
pushd test_rules
call npm ci --no-audit --no-fund || (popd & exit /b 1)
call npm test || (popd & echo Tests des regles en echec : deploiement annule. & exit /b 1)
popd
echo Deploiement des regles et des Cloud Functions sur %PROJECT_ID%...
call firebase deploy --only firestore:rules,firestore:indexes,storage,functions,hosting --project %PROJECT_ID% || exit /b 1
echo Deploiement termine.
