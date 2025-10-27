@echo off
REM Run emulator smoke test and capture stdout/stderr to a log file
REM Usage: run_emulator_smoke.cmd [with-functions]
setlocal
set PROJECT=b-link-local
nset LOGFILE=emulator_smoke_%DATE:~-10,2%-%DATE:~-7,2%-%DATE:~-4,4%_%TIME:~0,2%-%TIME:~3,2%-%TIME:~6,2%.log
necho Running emulator smoke test for project %PROJECT% > "%LOGFILE%"
echo Starting emulators and running smoke script... >> "%LOGFILE%"
if "%1"=="with-functions" (
  set CMD=firebase emulators:exec "node tool/client_smoke_emulator_puppet.js" --only auth,firestore,functions --project %PROJECT% --debug
) else (
  set CMD=firebase emulators:exec "node tool/client_smoke_emulator_puppet.js" --only auth,firestore --project %PROJECT% --debug
)

echo Command: %CMD% >> "%LOGFILE%"
%CMD% >> "%LOGFILE%" 2>&1
necho Exit code: %ERRORLEVEL% >> "%LOGFILE%"
echo Logs written to %LOGFILE%
echo To share the result, open %LOGFILE% and copy its contents.
endlocal
