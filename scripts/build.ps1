param([switch]$Preview)
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    dotnet publish windows-agent/MyRemote.Agent/MyRemote.Agent.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o artifacts/windows-agent
    if ($LASTEXITCODE) { throw 'Windows publish failed' }
    Push-Location mobile
    try {
        flutter pub get
        if ($LASTEXITCODE) { throw 'Flutter restore failed' }
        flutter build apk --debug
        if ($LASTEXITCODE) { throw 'Android build failed' }
        if ($Preview) {
            flutter build apk --release --split-per-abi
            if ($LASTEXITCODE) { throw 'Preview build failed' }
        }
    } finally { Pop-Location }
    Copy-Item -LiteralPath mobile/build/app/outputs/flutter-apk/app-debug.apk -Destination artifacts/MyRemote-debug.apk
    if ($Preview) {
        foreach ($abi in @('armeabi-v7a', 'arm64-v8a', 'x86_64')) {
            Copy-Item -LiteralPath "mobile/build/app/outputs/flutter-apk/app-$abi-release.apk" -Destination "artifacts/MyRemote-$abi-preview.apk"
        }
    }
    Compress-Archive -Path artifacts/windows-agent -DestinationPath artifacts/MyRemote-Windows-x64.zip -Force
    Write-Output 'Built artifacts/MyRemote-debug.apk and artifacts/windows-agent/MyRemote.Agent.exe'
} finally { Pop-Location }
