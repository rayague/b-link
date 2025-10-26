# PowerShell helper to run local Firebase emulator E2E test
# Usage: Open PowerShell, cd to repo root, run: .\tool\run_emulator_e2e.ps1

param(
    [int]$TimeoutSeconds = 60
)

function Wait-ForPort {
    param($hostname, $port, $timeoutSeconds)
    $start = Get-Date
    while ((Get-Date) - $start -lt (New-TimeSpan -Seconds $timeoutSeconds)) {
        try {
            $sock = New-Object System.Net.Sockets.TcpClient
            $iar = $sock.BeginConnect($hostname, $port, $null, $null)
            $wait = $iar.AsyncWaitHandle.WaitOne(1000)
            if ($wait -and $sock.Connected) {
                $sock.EndConnect($iar)
                $sock.Close()
                return $true
            }
            $sock.Close()
        } catch { }
        Start-Sleep -Seconds 1
    }
    return $false
}

Write-Host "Starting Firebase emulators (Firestore + Auth)..."
$cmd = 'firebase'
# Use cmd.exe /c to invoke the firebase CLI wrapper on Windows which may be a .cmd/.bat file
$proc = Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $cmd emulators:start --only firestore,auth --project b-link-local" -NoNewWindow -PassThru
Start-Sleep -Seconds 1
Write-Host "Waiting for emulator ports..."
$ok1 = Wait-ForPort -hostname 'localhost' -port 8080 -timeoutSeconds $TimeoutSeconds
$ok2 = Wait-ForPort -hostname 'localhost' -port 9099 -timeoutSeconds $TimeoutSeconds
if (-not ($ok1 -and $ok2)) {
    Write-Error "Emulator did not start within timeout. Check logs in the terminal where emulator started."
    exit 2
}

Write-Host "Emulators appear up. Creating anonymous user via Auth emulator..."
$signupResp = Invoke-RestMethod -Method Post -Uri 'http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake' -ContentType 'application/json' -Body '{}'
if (-not $signupResp) { Write-Error "Auth signUp failed"; exit 3 }
$localId = $signupResp.localId
$idToken = $signupResp.idToken
Write-Host "Created anonymous user: $localId"

Write-Host "Writing test profile document to Firestore emulator..."
$docPath = "http://localhost:8080/v1/projects/b-link-local/databases/(default)/documents/profiles/$localId"
$body = @{
    fields = @{
        name = @{ stringValue = 'E2E Test User' }
        birthDate = @{ stringValue = '1990-10-22' }
        birthDayKey = @{ stringValue = '10-22' }
    }
} | ConvertTo-Json -Depth 5

$headers = @{ 'Authorization' = "Bearer $idToken" }
try {
    $putResp = Invoke-RestMethod -Method Patch -Uri $docPath -Headers $headers -ContentType 'application/json' -Body $body -ErrorAction Stop
} catch {
    Write-Error "Write to Firestore emulator failed: $_"
    # Stop emulator before exit
    Write-Host "Stopping emulators..."
    Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $cmd emulators:stop --project b-link-local" -NoNewWindow -Wait
    exit 4
}

Write-Host "Document write response received. Verifying read-back..."
try {
    $getResp = Invoke-RestMethod -Method Get -Uri $docPath -Headers $headers -ErrorAction Stop
    if ($getResp) {
        Write-Host "Read back document OK. id: $localId"
        Write-Host (ConvertTo-Json $getResp -Depth 5)
    }
} catch {
    Write-Error "Failed to read back document: $_"
    Start-Process -FilePath 'cmd.exe' -ArgumentList "/c $cmd emulators:stop --project b-link-local" -NoNewWindow -Wait
    exit 5
}

Write-Host "E2E test succeeded. Stopping emulators..."
Start-Process -FilePath firebase -ArgumentList 'emulators:stop --project b-link-local' -NoNewWindow -Wait
Write-Host "Done."
