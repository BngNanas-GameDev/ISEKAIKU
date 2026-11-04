# Jalankan Flutter dengan rahasia dari `.env` sebagai --dart-define.
#
# Pemakaian:
#   .\scripts\flutter-env.ps1 run
#   .\scripts\flutter-env.ps1 run -d 192.168.1.3:36275
#   .\scripts\flutter-env.ps1 build apk --release
#   .\scripts\flutter-env.ps1 test
#
# Berkas `.env` TIDAK di-commit (lihat .gitignore). Salin dari `.env.example`.
#
# Pemetaan variabel:
#   URL           -> SUPABASE_URL
#   ANON_KEY      -> SUPABASE_ANON_KEY
#   ISEKAIKU_CID  -> ISEKAIKU_CID
#   SUPABASE_CID / SUPABASE_CS hanya untuk dashboard, tidak dibaca di sini.

param(
  [Parameter(Position = 0)]
  [string]$Action = "run",
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_env.ps1"

if (-not $env:FLUTTER_ROOT) {
  throw "Flutter tidak ditemukan. Set FLUTTER_ROOT atau pastikan flutter ada di PATH."
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

# --- petakan ke dart-define ---------------------------------------------
$mapping = [ordered]@{
  "URL"          = "SUPABASE_URL"
  "ANON_KEY"     = "SUPABASE_ANON_KEY"
  "ISEKAIKU_CID" = "ISEKAIKU_CID"
  "SAWERIA_STREAM_KEY" = "SAWERIA_STREAM_KEY"
}

$defines = @()
$found = @()
foreach ($key in $mapping.Keys) {
  if ($values.ContainsKey($key) -and $values[$key]) {
    $defines += "--dart-define=$($mapping[$key])=$($values[$key])"
    $found += $key
  }
}

if ($defines.Count -eq 0) {
  throw "Tidak ada nilai yang terbaca dari .env (URL / ANON_KEY / ISEKAIKU_CID)."
}

Write-Host ("Konfigurasi dari .env: " + ($found -join ", ")) -ForegroundColor DarkGray

# --- jalankan flutter ----------------------------------------------------
$flutter = Join-Path $env:FLUTTER_ROOT "bin\flutter.bat"

# Hanya perintah ini yang menerima --dart-define.
$supportsDefines = @("run", "build", "test", "install", "drive", "attach")
$allArgs = @()
if ($supportsDefines -contains $Action) {
  $allArgs = $FlutterArgs + $defines
} else {
  $allArgs = $FlutterArgs
  Write-Host "($Action tidak mendukung --dart-define; dijalankan tanpa rahasia)" -ForegroundColor DarkYellow
}

Push-Location $root
try {
  & $flutter $Action @allArgs
  exit $LASTEXITCODE
} finally {
  Pop-Location
}
