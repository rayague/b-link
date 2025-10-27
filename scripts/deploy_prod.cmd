@echo off
REM Deploy production Cloud Functions and Firestore rules (Windows cmd)
REM Usage: deploy_prod.cmd PROJECT_ID
set PROJECT_ID=%1
if "%PROJECT_ID%"=="" (
  echo Usage: %0 PROJECT_ID
  exit /b 2
)
where firebase >nul 2>&1 || (
  echo firebase CLI not found. Install with: npm install -g firebase-tools
  exit /b 2
)
echo Make sure you've enabled Blaze billing for project %PROJECT_ID% in Firebase Console.
echo Proceeding will deploy functions and rules to %PROJECT_ID%.
set /p CONT="Have you enabled Blaze for %PROJECT_ID%? (y/N) "
if /i not "%CONT%"=="y" (
  echo Aborting. Enable Blaze and re-run.
  exit /b 3
)
echo Deploying Cloud Functions to %PROJECT_ID%...
firebase deploy --only functions --project %PROJECT_ID%

nif exist firestore.rules.prod (
  copy /y firestore.rules.prod firestore.rules >nul
)
echo Deploying Firestore rules to %PROJECT_ID%...
firebase deploy --only firestore:rules --project %PROJECT_ID%
echo Deployment complete. Run smoke tests to validate production behavior.
