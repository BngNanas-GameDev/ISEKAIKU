# Pasang paket Android SDK yang dibutuhkan proyek ini (idempoten).
#
# Pemakaian:
#   .\scripts\setup-android-sdk.ps1                 # paket wajib saja
#   .\scripts\setup-android-sdk.ps1 -WithNdk        # + NDK (hanya jika perlu build native)
#   .\scripts\setup-android-sdk.ps1 -List           # tampilkan paket yang terpasang
#
# Butuh: JDK 17 + cmdline-tools (sdkmanager) di $env:ANDROID_HOME.
# Lihat README bagian "Setup Android SDK" untuk cara menyiapkan keduanya.

param(
  [switch]$WithNdk,
  [switch]$List,
  [string]$CompileSdk = "36"
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_env.ps1"
Write-ToolchainSummary

if (-not $env:ANDROID_HOME -or -not (Test-Path $env:ANDROID_HOME)) {
  throw "ANDROID_HOME tidak ditemukan. Jalankan setup dengan benar atau set variabel ANDROID_HOME."
}
if (-not $env:JAVA_HOME -or -not (Test-Path $env:JAVA_HOME)) {
  throw "JAVA_HOME tidak ditemukan. Android Gradle Plugin 8.7.3 butuh JDK 17."
}

$sdkmanager = Join-Path $env:ANDROID_HOME "cmdline-tools\latest\bin\sdkmanager.bat"
if (-not (Test-Path $sdkmanager)) {
  throw "sdkmanager tidak ada di $sdkmanager. Pasang cmdline-tools dulu (lihat README)."
}

# Gradle/AGP butuh build-tools yang cocok dengan compileSdk.
$packages = @(
  "platform-tools",
  "platforms;android-$CompileSdk",
  "build-tools;$CompileSdk.0.0"
)
if ($WithNdk) {
  # Versi default NDK untuk Flutter di mesin ini.
  $packages += "ndk;28.2.13676358"
}

if ($List) {
  & $sdkmanager --list_installed
  exit 0
}

Write-Host "Menerima lisensi SDK ..." -ForegroundColor Cyan
$yes = ("y`n" * 40)
$yes | & $sdkmanager --licenses

Write-Host "Memasang paket: $($packages -join ', ')" -ForegroundColor Cyan
& $sdkmanager $packages

Write-Host "Selesai. Verifikasi: flutter doctor -v" -ForegroundColor Green
