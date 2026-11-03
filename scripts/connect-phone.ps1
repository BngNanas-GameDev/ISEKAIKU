# Connect ke HP lewat wireless debugging, lalu jalankan Flutter.
#
# Pemakaian:
#   .\scripts\connect-phone.ps1                       # connect + flutter run
#   .\scripts\connect-phone.ps1 -Build                # connect + flutter build apk --debug
#   .\scripts\connect-phone.ps1 -Install              # connect + flutter install
#   .\scripts\connect-phone.ps1 -Pair -PairPort 46247 # pairing pertama kali
#   .\scripts\connect-phone.ps1 -Discover             # cari port connect otomatis via mDNS
#
# Port wireless debugging berubah setiap kali toggle-nya dimatikan. Setelah pairing,
# port connect berbeda dari port pairing: pakai -Discover atau lihat layar HP.

param(
  [string]$Ip = "192.168.1.3",
  [string]$Port = "",
  [switch]$Pair,
  [string]$PairPort,
  [switch]$Build,
  [switch]$Install,
  [switch]$Discover
)

$ErrorActionPreference = "Stop"

# Resolusi Flutter/JDK/SDK/adb tanpa hardcode path mesin.
. "$PSScriptRoot\_env.ps1"

if (-not $env:ADB -or -not (Test-Path $env:ADB)) {
  throw "adb tidak ditemukan. Set ANDROID_HOME atau tambahkan platform-tools ke PATH."
}
$adb = $env:ADB

Write-Host "adb: $adb" -ForegroundColor DarkGray
& $adb start-server | Out-Null

if ($Pair) {
  if (-not $PairPort) {
    throw "Pairing butuh -PairPort. Ambil dari HP: Wireless debugging > Pair device with pairing code."
  }
  Write-Host "Pairing ke ${Ip}:${PairPort} ..." -ForegroundColor Cyan
  & $adb pair "${Ip}:${PairPort}"
}

# Port connect bisa ditemukan lewat mDNS setelah pairing berhasil.
if (-not $Port -or $Discover) {
  $mdns = (& $adb mdns services 2>$null) | Select-String -Pattern "_adb-tls-connect\._tcp" |
    Select-String -Pattern ([regex]::Escape($Ip))
  if ($mdns) {
    $line = ($mdns | Select-Object -Last 1).Line
    if ($line -match "($([regex]::Escape($Ip)):\d+)") {
      $Port = ($Matches[1] -split ":")[1]
      Write-Host "Port connect terdeteksi via mDNS: $Port" -ForegroundColor DarkGray
    }
  }
}

if (-not $Port) {
  throw "Port connect belum diketahui. Jalankan dengan -Port <port> atau -Discover setelah pairing."
}

$target = "${Ip}:${Port}"

Write-Host "Menghubungkan ke $target ..." -ForegroundColor Cyan
& $adb connect $target | Out-Null

$state = (& $adb devices) | Select-String -Pattern ([regex]::Escape($target))
if (-not $state -or $state -notmatch "device$") {
  Write-Warning "HP belum terhubung. Cek:"
  Write-Host "  1. Wireless debugging masih ON dan port masih $Port (port berubah setelah reboot/toggle)"
  Write-Host "  2. Sudah pernah pairing dengan PC ini (-Pair -PairPort <port> saat pertama kali)"
  Write-Host "  3. HP dan PC saling ping: Test-Connection $Ip"
  Write-Host "  4. Coba -Discover untuk mencari port connect via mDNS"
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
