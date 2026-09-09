$ErrorActionPreference = 'Stop'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Install Flutter SDK and add flutter/bin to PATH first.'
}
$mobilePath = Join-Path $PSScriptRoot '../mobile'
Push-Location $mobilePath
try {
    # Fill missing native/Gradle files without overwriting existing files.
    flutter create --platforms=android --org com.myremote --project-name myremote --no-pub .
    if ($LASTEXITCODE -ne 0) { throw 'Flutter project generation failed.' }
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency restore failed.' }
    flutter analyze lib
    if ($LASTEXITCODE -ne 0) { throw 'Flutter analysis failed.' }
} finally { Pop-Location }
