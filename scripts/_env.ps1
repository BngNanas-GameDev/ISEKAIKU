# Resolusi toolchain (Flutter, JDK, Android SDK, adb) tanpa hardcode path.
# Di-dot-source oleh connect-phone.ps1 dan deploy-phone.ps1:
#
#   . "$PSScriptRoot\_env.ps1"
#
# Urutan pencarian: environment variable yang sudah ada -> lokasi umum.
# Kalau ada yang tidak ketemu, script pemanggil yang memutuskan apakah fatal.

function Find-ToolPath {
  param([string[]]$Candidates)

  foreach ($c in $Candidates) {
    if (-not $c) { continue }
    $expanded = [Environment]::ExpandEnvironmentVariables($c)
    # Dukung wildcard, mis. "C:\Program Files\Eclipse Adoptium\jdk-17*"
    if ($expanded -match '[\*\?]') {
      $hit = Get-ChildItem -Path $expanded -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1
      if ($hit) { return $hit.FullName }
    } elseif (Test-Path $expanded) {
      return (Resolve-Path $expanded).Path
    }
  }

  return $null
}

# --- Flutter -------------------------------------------------------------
if (-not $env:FLUTTER_ROOT) {
  $flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
  if ($flutterCmd) {
    $env:FLUTTER_ROOT = Split-Path (Split-Path $flutterCmd.Source -Parent) -Parent
  }
}
if (-not $env:FLUTTER_ROOT) {
  $flutterBat = Find-ToolPath @(
    "D:\VSCODE\App\flutter\bin\flutter.bat",
    "C:\flutter\bin\flutter.bat",
    "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
    "$env:USERPROFILE\flutter\bin\flutter.bat",
    "D:\flutter\bin\flutter.bat"
  )
  if ($flutterBat) { $env:FLUTTER_ROOT = Split-Path (Split-Path $flutterBat -Parent) -Parent }
}
if ($env:FLUTTER_ROOT) {
  $flutterBin = Join-Path $env:FLUTTER_ROOT "bin"
  if (($env:PATH -split ";") -notcontains $flutterBin) {
    $env:PATH = "$flutterBin;$env:PATH"
  }
}

# --- JDK 17 --------------------------------------------------------------
if (-not $env:JAVA_HOME) {
  $env:JAVA_HOME = Find-ToolPath @(
    "D:\Android\jdk17",
    "C:\Program Files\Eclipse Adoptium\jdk-17*",
    "C:\Program Files\Java\jdk-17*",
    "C:\Program Files\Microsoft\jdk-17*",
    "$env:LOCALAPPDATA\Programs\Eclipse Adoptium\jdk-17*"
  )
}
if ($env:JAVA_HOME) {
  $jdkBin = Join-Path $env:JAVA_HOME "bin"
  if (($env:PATH -split ";") -notcontains $jdkBin) {
    $env:PATH = "$jdkBin;$env:PATH"
  }
}

# --- Android SDK ---------------------------------------------------------
if (-not $env:ANDROID_HOME) {
  $env:ANDROID_HOME = Find-ToolPath @(
    "$env:LOCALAPPDATA\Android\Sdk",
    "D:\Android\sdk",
    "C:\Android\sdk",
    "D:\Android\Sdk"
  )
}
if ($env:ANDROID_HOME) {
  $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
  foreach ($sub in @("platform-tools", "cmdline-tools\latest\bin", "emulator")) {
    $p = Join-Path $env:ANDROID_HOME $sub
    if ((Test-Path $p) -and (($env:PATH -split ";") -notcontains $p)) {
      $env:PATH = "$p;$env:PATH"
    }
  }
}

# --- adb -----------------------------------------------------------------
$adbCandidates = @()
if ($env:ANDROID_HOME) { $adbCandidates += (Join-Path $env:ANDROID_HOME "platform-tools\adb.exe") }
$adbCandidates += @(
  "D:\Android\sdk\platform-tools\adb.exe",
  "C:\Android\sdk\platform-tools\adb.exe",
  "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
  "D:\scrcpy-win64*\adb.exe",
  "C:\scrcpy-win64*\adb.exe"
)
$env:ADB = Find-ToolPath $adbCandidates
if (-not $env:ADB) {
  $adbCmd = Get-Command adb -ErrorAction SilentlyContinue
  if ($adbCmd) { $env:ADB = $adbCmd.Source }
}

function Write-ToolchainSummary {
  $flutterVersion = if ($env:FLUTTER_ROOT) { Split-Path $env:FLUTTER_ROOT -Leaf } else { "(tidak ditemukan)" }
  Write-Host "Toolchain:" -ForegroundColor DarkGray
  Write-Host "  Flutter  : $($env:FLUTTER_ROOT)  [$flutterVersion]" -ForegroundColor DarkGray
  Write-Host "  JAVA_HOME: $($env:JAVA_HOME)" -ForegroundColor DarkGray
  Write-Host "  SDK      : $($env:ANDROID_HOME)" -ForegroundColor DarkGray
  Write-Host "  adb      : $($env:ADB)" -ForegroundColor DarkGray
}
