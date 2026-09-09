$ErrorActionPreference = 'Stop'
$agentPath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../artifacts/windows-agent/MyRemote.Agent.exe'))
if (-not (Test-Path -LiteralPath $agentPath)) { throw 'Run scripts/build.ps1 or dotnet publish first.' }
$previousKey = $env:MYREMOTE_KEY
$env:MYREMOTE_KEY = [Guid]::NewGuid().ToString('N')
$process = $null
try {
    $process = Start-Process -FilePath $agentPath -ArgumentList '--urls http://127.0.0.1:18765' -WindowStyle Hidden -PassThru
    $ready = $false
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        if ($process.HasExited) { throw 'Agent stopped unexpectedly.' }
        try {
            Invoke-RestMethod 'http://127.0.0.1:18765/health' | Out-Null
            $ready = $true
            break
        } catch { Start-Sleep -Milliseconds 200 }
    }
    if (-not $ready) { throw 'Agent did not start.' }
    & (Join-Path $PSScriptRoot 'test-agent.ps1') -Endpoint 'ws://127.0.0.1:18765/ws'
} finally {
    if ($null -ne $process -and -not $process.HasExited) { Stop-Process -Id $process.Id }
    $env:MYREMOTE_KEY = $previousKey
}
