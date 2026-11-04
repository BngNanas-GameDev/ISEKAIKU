# Build APK dengan konfigurasi dari `.env` (SUPABASE_URL, SUPABASE_ANON_KEY,
# ISEKAIKU_CID) sebagai --dart-define.
#
# Pemakaian:
#   .\scripts\build-apk.ps1                 # debug
#   .\scripts\build-apk.ps1 -Release        # release
#   .\scripts\build-apk.ps1 -Bundle         # AAB untuk Play Store
#   .\scripts\build-apk.ps1 -Install        # debug + pasang ke HP
#   .\scripts\build-apk.ps1 -Release -Install -Device 192.168.1.3:36275
#
# Berkas `.env` tidak di-commit; salin dari `.env.example`.

param(
  [switch]$Release,
  [switch]$Bundle,
  [switch]$Install,
  [string]$Device = ""
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_env.ps1"

if (-not $env:FLUTTER_ROOT) {
  throw "Flutter tidak ditemukan. Set FLUTTER_ROOT."
}

$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root ".env"
if (-not (Test-Path $envFile)) {
  throw "File .env belum ada. Salin .env.example menjadi .env lalu isi nilainya."
}

# --- baca .env -----------------------------------------------------------
$values = @{}
Get-Content $envFile | ForEach-Object {
  $line = $_.Trim()
  if ($line -eq "" -or $line.StartsWith("#")) { return }
  $idx = $line.IndexOf("=")
  if ($idx -lt 1) { return }
  $key = $line.Substring(0, $idx).Trim()
  $value = $line.Substring($idx + 1).Trim()
  if ($value.Length -ge 2) {
    $first = $value.Substring(0, 1)
    $last = $value.Substring($value.Length - 1, 1)
    if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
      $value = $value.Substring(1, $value.Length - 2)
    }
  }
  $values[$key] = $value
}

$mapping = [ordered]@{
  "URL"          = "SUPABASE_URL"
  "ANON_KEY"     = "SUPABASE_ANON_KEY"
  "ISEKAIKU_CID" = "ISEKAIKU_CID"
}

$defines = @()
$found = @()
foreach ($key in $mapping.Keys) {
  if ($values.ContainsKey($key) -and $values[$key]) {
    $defines += "--dart-define=$($mapping[$key])=$($values[$key])"
    $found += $key
  }
}

Write-Host ("Konfigurasi dari .env: " + ($found -join ", ")) -ForegroundColor DarkGray

$mode = if ($Release -or $Bundle) { "--release" } else { "--debug" }
$apkName = if ($Release -or $Bundle) { "app-release.apk" } else { "app-debug.apk" }
$apkPath = Join-Path $root "build\app\outputs\flutter-apk\$apkName"
$aabPath = Join-Path $root "build\app\outputs\bundle\release\app-release.aab"

$flutter = Join-Path $env:FLUTTER_ROOT "bin\flutter.bat"

Push-Location $root
try {
  if ($Bundle) {
    & $flutter build appbundle --release @defines
  } else {
    & $flutter build apk $mode @defines
  }
  if ($LASTEXITCODE -ne 0) {
    throw "Build gagal (exit $LASTEXITCODE)."
  }
} finally {
  Pop-Location
}

if ($Bundle) {
  Write-Host "AAB: $aabPath" -ForegroundColor Green
  return
}

Write-Host "APK: $apkPath" -ForegroundColor Green

# --- pasang kalau diminta -------------------------------------------------
if ($Install) {
  if (-not $env:ADB) { throw "adb tidak ditemukan." }

  $target = $Device
  if (-not $target) {
    $lines = & $env:ADB devices
    $target = ($lines | Select-String -Pattern "^\S+\s+device$" | Select-Object -First 1)
    if ($target) { $target = ($target.ToString() -split "\s+")[0] }
  }
  if (-not $target) { throw "Tidak ada perangkat. Jalankan connect-phone.ps1 dulu." }

  Write-Host "Memasang ke $target ..." -ForegroundColor Cyan
  & $env:ADB -s $target install -r $apkPath
  & $env:ADB -s $target shell "am force-stop com.isekaiku.isekaiku"
  & $env:ADB -s $target shell "am start -n com.isekaiku.isekaiku/.MainActivity" | Out-Null
  Write-Host "Selesai." -ForegroundColor Green
}
