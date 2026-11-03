# Connect ke HP Musam lewat wireless debugging, lalu jalankan Flutter.
#
# Pemakaian:
#   .\scripts\connect-phone.ps1                 # connect + flutter run
#   .\scripts\connect-phone.ps1 -Build          # connect + flutter build apk --debug
#   .\scripts\connect-phone.ps1 -Pair           # pairing pertama kali
#
# Port wireless debugging berubah setiap kali toggle-nya dimatikan.
# Kalau connect gagal, lihat layar Wireless debugging di HP dan perbarui -Port.

param(
  [string]$Ip = "192.168.6.21",
  [string]$Port = "35183",
  [switch]$Pair,
  [string]$PairPort,
  [switch]$Build,
  [switch]$Install
)

$ErrorActionPreference = "Stop"

$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"
$env:ANDROID_HOME = "C:\Android\sdk"
$env:ANDROID_SDK_ROOT = "C:\Android\sdk"
$adb = "C:\Android\sdk\platform-tools\adb.exe"
$target = "${Ip}:${Port}"

if (-not (Test-Path $adb)) {
  throw "adb tidak ditemukan di $adb"
}

& $adb start-server | Out-Null

if ($Pair) {
  if (-not $PairPort) {
    throw "Pairing butuh -PairPort. Ambil dari HP: Wireless debugging > Pair device with pairing code."
  }
  Write-Host "Pairing ke ${Ip}:${PairPort} ..." -ForegroundColor Cyan
  & $adb pair "${Ip}:${PairPort}"
}

Write-Host "Menghubungkan ke $target ..." -ForegroundColor Cyan
& $adb connect $target

$state = (& $adb devices) | Select-String -Pattern ([regex]::Escape($target))
if (-not $state -or $state -notmatch "device$") {
  Write-Warning "HP belum terhubung. Cek:"
  Write-Host "  1. Wireless debugging masih ON dan port masih $Port (port berubah setelah reboot/toggle)"
  Write-Host "  2. Sudah pernah pairing dengan PC ini (-Pair -PairPort <port> saat pertama kali)"
  Write-Host "  3. HP dan PC saling ping: Test-Connection $Ip"
  exit 1
}

Write-Host "Terhubung: $target" -ForegroundColor Green

if ($Build) {
  flutter build apk --debug
} elseif ($Install) {
  flutter install -d $target
} else {
  flutter run -d $target
}
