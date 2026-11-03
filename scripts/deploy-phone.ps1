# Build APK debug, install ke HP, jalankan, lalu ambil screenshot.
#
# Pemakaian:
#   .\scripts\deploy-phone.ps1
#   .\scripts\deploy-phone.ps1 -Ip 192.168.1.3 -Port 37331 -Shot out.png
#   .\scripts\deploy-phone.ps1 -SkipBuild          # pakai APK yang sudah ada
#
# Kalau -Port kosong, port connect dicari otomatis lewat mDNS (perlu sudah pairing).

param(
  [string]$Ip = "192.168.1.3",
  [string]$Port = "",
  [string]$Apk = "build\app\outputs\flutter-apk\app-debug.apk",
  [string]$Shot = "",
  [string]$Package = "com.isekaiku.isekaiku",
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

# Resolusi Flutter/JDK/SDK/adb tanpa hardcode path mesin.
. "$PSScriptRoot\_env.ps1"

if (-not $env:ADB -or -not (Test-Path $env:ADB)) {
  throw "adb tidak ditemukan. Set ANDROID_HOME atau tambahkan platform-tools ke PATH."
}
$adb = $env:ADB

Write-Host "adb: $adb" -ForegroundColor DarkGray

if (-not $Port) {
  $mdns = (& $adb mdns services 2>$null) | Select-String -Pattern "_adb-tls-connect\._tcp" |
    Select-String -Pattern ([regex]::Escape($Ip))
  if ($mdns) {
    $line = ($mdns | Select-Object -Last 1).Line
    if ($line -match "($([regex]::Escape($Ip)):\d+)") {
      $Port = ($Matches[1] -split ":")[1]
    }
  }
}

if (-not $Port) {
  throw "Port connect belum diketahui. Jalankan dengan -Port <port> atau pair dulu lewat connect-phone.ps1 -Pair."
}

$target = "${Ip}:${Port}"

& $adb connect $target | Out-Null
$state = (& $adb devices) | Select-String -Pattern ([regex]::Escape($target))
if (-not $state -or $state -notmatch "device$") {
  throw "HP tidak terhubung di $target. Cek Wireless debugging / jalankan scripts\connect-phone.ps1 -Discover"
}

if (-not $SkipBuild) {
  Write-Host "Build APK debug ..." -ForegroundColor Cyan
  flutter build apk --debug
}

if (-not (Test-Path $Apk)) {
  throw "APK tidak ditemukan: $Apk"
}

Write-Host "Install $Apk ..." -ForegroundColor Cyan
& $adb -s $target install -r $Apk

& $adb -s $target shell "am start -n $Package/.MainActivity" | Out-Null
Start-Sleep -Seconds 4

if ($Shot) {
  & $adb -s $target exec-out screencap -p > $Shot
  Write-Host "Screenshot: $Shot" -ForegroundColor Green
}

Write-Host "Selesai. App berjalan di $target" -ForegroundColor Green
