param(
  [int]$firestorePort = 8080,
  [int]$authPort = 9099,
  [string]$project = 'b-link-local'
)

Write-Host "Starting Firebase emulators (firestore:$firestorePort auth:$authPort) for project $project"

# Ensure firebase CLI exists
$firebaseCmd = Get-Command firebase -ErrorAction SilentlyContinue
if (-not $firebaseCmd) {
  Write-Error "Firebase CLI not found in PATH. Install it (npm install -g firebase-tools) and login (firebase login), then re-run this script."
  exit 10
}

# Start emulator in a new background process using cmd /c so Windows can execute npm shims correctly
$proc = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c firebase emulators:start --only firestore,auth --project $project" -NoNewWindow -PassThru

Write-Host "Waiting for emulator ports to be ready..."


function Wait-Port($h, $port, $timeoutSec=30) {
  $deadline = (Get-Date).AddSeconds($timeoutSec)
  while((Get-Date) -lt $deadline) {
    try {
      $r = Test-NetConnection -ComputerName $h -Port $port -WarningAction SilentlyContinue
      if ($r.TcpTestSucceeded) { return $true }
    } catch {}
    Start-Sleep -Seconds 1
  }
  return $false
}

if (-not (Wait-Port -host '127.0.0.1' -port $firestorePort -timeoutSec 60)) {
  Write-Error "Firestore emulator did not start in time"
  exit 2
}
if (-not (Wait-Port -host '127.0.0.1' -port $authPort -timeoutSec 60)) {
  Write-Error "Auth emulator did not start in time"
  exit 3
}

Write-Host "Emulators running. Running client smoke test against emulator..."

# Run the client smoke puppet script which connects to emulator endpoints
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) { Write-Error 'Node.js not found in PATH'; exit 4 }

$env:FIRESTORE_EMULATOR_HOST = "127.0.0.1:$firestorePort"
$env:FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:$authPort"

# Execute the test
$testProc = Start-Process -FilePath $node.Path -ArgumentList '.\tool\client_smoke_emulator_puppet.js' -NoNewWindow -Wait -PassThru
$exitCode = $testProc.ExitCode

Write-Host "Client smoke test exit code: $exitCode"

Write-Host "Stopping emulators..."
try {
  $proc.Kill()
} catch {}

exit $exitCode
