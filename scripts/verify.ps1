$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    dotnet build windows-agent/MyRemote.Agent/MyRemote.Agent.csproj
    if ($LASTEXITCODE) { throw 'Agent build failed' }
    Push-Location mobile
    try {
        flutter analyze
        if ($LASTEXITCODE) { throw 'Flutter analysis failed' }
        flutter test
        if ($LASTEXITCODE) { throw 'Flutter tests failed' }
    } finally { Pop-Location }
    Write-Output 'PASS: build, analysis and Flutter tests. Run test-agent.ps1 with the running agent key for integration tests.'
} finally { Pop-Location }
