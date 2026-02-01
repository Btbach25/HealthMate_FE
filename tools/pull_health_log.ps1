# Requires Android device connected and app installed/running at least once.
# Copies health_sync.json from app's internal support dir to repo assets.

param(
    [string]$Package = "com.example.fe",
    [string]$Dest = "assets/debug/health/sample_health_sync.json"
)

Write-Host "Pulling health_sync.json from device for package '$Package'..."

# Export to device's public storage first, then pull to local repo.
$exportOnDevice = "/sdcard/Download/health_sync.json"

# Verify ADB connectivity
$devices = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "\S+\s+device" }
if (-not $devices) {
    Write-Error "Không thấy thiết bị ADB ở trạng thái 'device'. Hãy bật USB debugging, cắm cáp và chấp nhận RSA prompt."
    exit 1
}

# Ensure app data exists and file is present
$checkCmd = "run-as $Package ls files/health_sync.json"
$check = adb shell $checkCmd 2>&1
if ($check -match "No such file" -or $check -match "does not exist") {
    Write-Error "Không tìm thấy 'files/health_sync.json'. Hãy chạy app và đảm bảo đã gọi JsonLogger.append(...) trước khi kéo."
    exit 2
}

# Dump file from app's internal storage to public path
adb shell run-as $Package sh -c "cat files/health_sync.json > $exportOnDevice"

# Ensure destination directory exists
$destDir = Split-Path -Parent $Dest
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir | Out-Null
}

# Pull to repo
adb pull $exportOnDevice $Dest | Out-Null

Write-Host "Log pulled to '$Dest'"
