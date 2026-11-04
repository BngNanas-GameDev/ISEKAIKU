# Membuat keystore rilis + android/key.properties.
#
# Pemakaian:
#   .\scripts\make-keystore.ps1
#   .\scripts\make-keystore.ps1 -Alias isekaiku -ValidityDays 10000
#
# Password ditanyakan saat dijalankan. JANGAN commit keystore maupun
# key.properties — keduanya sudah diabaikan git.
#
# Setelah selesai, build rilis:
#   .\scripts\build-apk.ps1 -Release

param(
  [string]$Alias = "isekaiku",
  [int]$ValidityDays = 10000,
  [string]$Dname = "CN=Isekaiku, OU=Development, O=Isekaiku, L=Jakarta, ST=DKI Jakarta, C=ID"
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_env.ps1"

if (-not $env:JAVA_HOME) {
  throw "JAVA_HOME tidak ditemukan. Pasang JDK 17 dulu."
}

$keytool = Join-Path $env:JAVA_HOME "bin\keytool.exe"
if (-not (Test-Path $keytool)) {
  throw "keytool tidak ada di $keytool"
}

$root = Split-Path $PSScriptRoot -Parent
$appDir = Join-Path $root "android\app"
$keystorePath = Join-Path $appDir "release-keystore.jks"
$propertiesPath = Join-Path $root "android\key.properties"

if (Test-Path $keystorePath) {
  $answer = Read-Host "Keystore sudah ada ($keystorePath). Timpa? (y/N)"
  if ($answer -ne "y") {
    Write-Host "Dibatalkan." -ForegroundColor Yellow
    exit 0
  }
}

Write-Host "Membuat keystore rilis..." -ForegroundColor Cyan
$secure = Read-Host "Password keystore" -AsSecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))

if ($plain.Length -lt 6) {
  throw "Password minimal 6 karakter."
}

& $keytool -genkeypair -v `
  -keystore $keystorePath `
  -alias $Alias `
  -keyalg RSA -keysize 2048 -validity $ValidityDays `
  -storepass $plain -keypass $plain `
  -dname $Dname

if ($LASTEXITCODE -ne 0) { throw "keytool gagal (exit $LASTEXITCODE)." }

$content = @"
storeFile=release-keystore.jks
storePassword=$plain
keyAlias=$Alias
keyPassword=$plain
"@

Set-Content -Path $propertiesPath -Value $content -Encoding ASCII

Write-Host ""
Write-Host "Selesai." -ForegroundColor Green
Write-Host "  Keystore : $keystorePath"
Write-Host "  Properti : $propertiesPath"
Write-Host ""
Write-Host "PENTING: simpan password di tempat aman. Tanpa itu, aplikasi tidak" -ForegroundColor Yellow
Write-Host "bisa di-update di Play Store." -ForegroundColor Yellow

Write-Host ""
Write-Host "SHA-1 untuk Google Sign-In:" -ForegroundColor Cyan
& $keytool -list -v -keystore $keystorePath -alias $Alias -storepass $plain 2>&1 |
  Select-String -Pattern "SHA1:|SHA256:" |
  ForEach-Object { "  " + $_.Line.Trim() }
