# Build APK debug, install ke HP, jalankan, lalu ambil screenshot.
#
# Pemakaian:
#   .\scripts\deploy-phone.ps1
#   .\scripts\deploy-phone.ps1 -Ip 192.168.6.21 -Port 35183 -Shot out.png

param(
  [string]$Ip = "192.168.6.21",
  [string]$Port = "35183",
  [string]$Apk = "build\app\outputs\flutter-apk\app-debug.apk",
  [string]$Shot = "",
  [string]$Package = "com.isekaiku.isekaiku",
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"
$env:ANDROID_HOME = "C:\Android\sdk"
$env:ANDROID_SDK_ROOT = "C:\Android\sdk"
$env:PATH = "C:\Android\sdk\platform-tools;$env:PATH"

$adb = "C:\Android\sdk\platform-tools\adb.exe"
$target = "${Ip}:${Port}"

& $adb connect $target | Out-Null
$state = (& $adb devices) | Select-String -Pattern ([regex]::Escape($target))
if (-not $state -or $state -notmatch "device$") {
  throw "HP tidak terhubung di $target. Cek Wireless debugging / jalankan scripts\connect-phone.ps1"
}

if (-not $SkipBuild) {
  flutter build apk --debug
}

& $adb -s $target install -r $Apk
& $adb -s $target shell "am start -n $Package/.MainActivity" | Out-Null
Start-Sleep -Seconds 4

if ($Shot) {
  & $adb -s $target exec-out screencap -p > $Shot
  Write-Host "Screenshot: $Shot" -ForegroundColor Green
}

Write-Host "Selesai. App berjalan di $target" -ForegroundColor Green
