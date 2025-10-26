# Runs a simple smoke test against a live Firestore database.
# Modes:
#  - client: create anonymous user via Firebase Auth REST (requires Web API key) and write/read a document using idToken.
#  - admin: run the Node admin viewer (requires a service account JSON and Node) to read documents (bypasses security rules).

param(
  [ValidateSet("client","admin")]
  [string]$Mode = 'client',
  [string]$Project = '',
  [string]$DocId = 'smoke-test-user',
  [string]$ApiKey = '',
  [string]$ServiceKey = ''
)

function Write-ErrAndExit($msg, $code=1) {
  Write-Host "ERROR: $msg" -ForegroundColor Red
  exit $code
}

if ($Mode -eq 'client') {
  if (-not $ApiKey) { Write-ErrAndExit 'Client mode requires -ApiKey (Web API key from Firebase console).' }
  if (-not $Project) { Write-Host 'No project specified; using API responses to target project.' }

  Write-Host "[client] Creating anonymous user via Auth REST..."
  $signUpUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$ApiKey"
  $body = '{"returnSecureToken":true}'
  try {
    $resp = Invoke-RestMethod -Method Post -Uri $signUpUrl -ContentType 'application/json' -Body $body -ErrorAction Stop
  } catch {
    Write-ErrAndExit "Auth signUp failed: $($_.Exception.Message)"
  }
  $idToken = $resp.idToken
  $localId = $resp.localId
  if (-not $idToken) { Write-ErrAndExit 'No idToken returned from Auth.' }
  Write-Host "Got localId: $localId"

  $docBody = @{ fields = @{ name = @{ stringValue = 'Smoke Test User' }; birthDate = @{ stringValue = '2000-01-01' }; lastSyncedAt = @{ timestampValue = (Get-Date).ToString('o') } } } | ConvertTo-Json -Depth 6

  $fsUrl = "https://firestore.googleapis.com/v1/projects/$($Project)/databases/(default)/documents/profiles?documentId=$DocId"
  Write-Host "[client] Writing document to $fsUrl"
  try {
    $w = Invoke-RestMethod -Method Post -Uri $fsUrl -Headers @{ Authorization = "Bearer $idToken" } -ContentType 'application/json' -Body $docBody -ErrorAction Stop
    Write-Host 'Write successful. Document response:'
    $w | ConvertTo-Json -Depth 6 | Write-Host
  } catch {
    Write-Host "Write failed: $($_.Exception.Message)" -ForegroundColor Yellow
    if ($_.Exception.Response -ne $null) { $_.Exception.Response.GetResponseStream() | %{ (New-Object System.IO.StreamReader($_)).ReadToEnd() } | Write-Host }
  }

  $getUrl = "https://firestore.googleapis.com/v1/projects/$($Project)/databases/(default)/documents/profiles/$DocId"
  Write-Host "[client] Reading back document $getUrl"
  try {
    $g = Invoke-RestMethod -Method Get -Uri $getUrl -Headers @{ Authorization = "Bearer $idToken" } -ErrorAction Stop
    Write-Host 'Read successful. Document:'
    $g | ConvertTo-Json -Depth 6 | Write-Host
  } catch {
    Write-Host "Read failed: $($_.Exception.Message)" -ForegroundColor Yellow
    if ($_.Exception.Response -ne $null) { $_.Exception.Response.GetResponseStream() | %{ (New-Object System.IO.StreamReader($_)).ReadToEnd() } | Write-Host }
  }
  exit 0
}

if ($Mode -eq 'admin') {
  if ($ServiceKey) { $env:GOOGLE_APPLICATION_CREDENTIALS = $ServiceKey }
  if (-not $env:GOOGLE_APPLICATION_CREDENTIALS) { Write-ErrAndExit 'Admin mode requires GOOGLE_APPLICATION_CREDENTIALS env var or -ServiceKey parameter.' }
  if (-not (Test-Path $env:GOOGLE_APPLICATION_CREDENTIALS)) { Write-ErrAndExit "Service key not found at $env:GOOGLE_APPLICATION_CREDENTIALS" }

  Write-Host "[admin] Running admin viewer with credentials: $env:GOOGLE_APPLICATION_CREDENTIALS"
  $node = Get-Command node -ErrorAction SilentlyContinue
  if (-not $node) { Write-ErrAndExit 'Node.js not found in PATH. Install Node.js to run admin viewer.' }
  Push-Location $PSScriptRoot\..\
  try {
    & node .\tool\view_firestore_admin.js --limit 200
  } finally {
    Pop-Location
  }
  exit 0
}
