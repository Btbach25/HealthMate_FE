<#
.SYNOPSIS
    Bản PowerShell tương đương Makefile — dùng khi máy Windows chưa cài `make`.

.DESCRIPTION
    Mọi lệnh đều khớp 1-1 với target trong Makefile ở thư mục gốc.

.EXAMPLE
    .\tool\dev.ps1              # xem danh sách lệnh
    .\tool\dev.ps1 setup        # cài đặt lần đầu sau khi clone
    .\tool\dev.ps1 run-demo     # chạy app bằng dữ liệu giả lập
    .\tool\dev.ps1 check        # chạy đúng bộ kiểm tra của CI
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = 'help'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

$WebPort = 5000

# Mô tả hiển thị trong `help`, giữ đồng bộ với Makefile.
$Commands = [ordered]@{
    'setup'          = 'Cài đặt lần đầu: tạo .env từ .env.example rồi pub get'
    'get'            = 'Tải dependencies'
    'doctor'         = 'Kiểm tra môi trường Flutter'
    'fmt'            = 'Format toàn bộ code Dart'
    'fmt-check'      = 'Kiểm tra format, fail nếu có file chưa format'
    'analyze'        = 'Phân tích tĩnh'
    'test'           = 'Chạy unit/widget test'
    'check'          = 'fmt-check + analyze + test (chạy trước khi mở PR)'
    'run'            = 'Chạy trên thiết bị/emulator (gọi API thật)'
    'run-demo'       = 'Chạy với dữ liệu giả lập, không cần backend'
    'run-web'        = "Chạy trên Chrome (port $WebPort để Google OAuth hoạt động)"
    'run-web-demo'   = 'Chạy trên Chrome với dữ liệu giả lập'
    'adb-reverse'    = 'Trỏ localhost:8080 của máy Android thật về máy tính'
    'build-apk'      = 'Build APK release'
    'build-aab'      = 'Build Android App Bundle'
    'build-web'      = 'Build bản web release'
    'build-demo-apk' = 'Build APK demo chạy hoàn toàn bằng mock data'
    'build-demo-web' = 'Build web demo chạy hoàn toàn bằng mock data'
    'icons'          = 'Sinh lại app icon'
    'splash'         = 'Sinh lại native splash screen'
    'outdated'       = 'Liệt kê dependency có bản mới'
    'upgrade'        = 'Nâng dependency trong phạm vi ràng buộc pubspec'
    'clean'          = 'Xoá build artifacts'
    'reset'          = 'clean + pub get (dùng khi build lỗi lạ)'
}

function Invoke-Step {
    param([string]$Exe, [string[]]$Arguments)
    Write-Host "> $Exe $($Arguments -join ' ')" -ForegroundColor DarkGray
    & $Exe @Arguments
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

function Show-Help {
    Write-Host ''
    Write-Host 'HealthMate FE — .\tool\dev.ps1 <lệnh>' -ForegroundColor Cyan
    Write-Host ''
    foreach ($key in $Commands.Keys) {
        Write-Host ('  {0,-16} {1}' -f $key, $Commands[$key])
    }
    Write-Host ''
}

switch ($Command) {
    'help' { Show-Help }

    'setup' {
        if (-not (Test-Path '.env')) {
            Copy-Item '.env.example' '.env'
            Write-Host 'Đã tạo .env từ .env.example — nhớ điền BASE_URL và GOOGLE_CLIENT_ID.' -ForegroundColor Yellow
        }
        Invoke-Step 'flutter' @('pub', 'get')
    }

    'get'     { Invoke-Step 'flutter' @('pub', 'get') }
    'doctor'  { Invoke-Step 'flutter' @('doctor', '-v') }

    'fmt'       { Invoke-Step 'dart' @('format', '.') }
    'fmt-check' { Invoke-Step 'dart' @('format', '--output=none', '--set-exit-if-changed', '.') }
    'analyze'   { Invoke-Step 'flutter' @('analyze') }
    'test'      { Invoke-Step 'flutter' @('test') }

    'check' {
        Invoke-Step 'dart'    @('format', '--output=none', '--set-exit-if-changed', '.')
        Invoke-Step 'flutter' @('analyze')
        Invoke-Step 'flutter' @('test')
    }

    'run'          { Invoke-Step 'flutter' @('run') }
    'run-demo'     { Invoke-Step 'flutter' @('run', '--dart-define=DEMO_MODE=true') }
    'run-web'      { Invoke-Step 'flutter' @('run', '-d', 'chrome', "--web-port=$WebPort") }
    'run-web-demo' { Invoke-Step 'flutter' @('run', '-d', 'chrome', "--web-port=$WebPort", '--dart-define=DEMO_MODE=true') }

    'adb-reverse'  { Invoke-Step 'adb' @('reverse', 'tcp:8080', 'tcp:8080') }

    'build-apk'      { Invoke-Step 'flutter' @('build', 'apk', '--release') }
    'build-aab'      { Invoke-Step 'flutter' @('build', 'appbundle', '--release') }
    'build-web'      { Invoke-Step 'flutter' @('build', 'web', '--release') }
    'build-demo-apk' { Invoke-Step 'flutter' @('build', 'apk', '--release', '--dart-define=DEMO_MODE=true') }
    'build-demo-web' { Invoke-Step 'flutter' @('build', 'web', '--release', '--dart-define=DEMO_MODE=true') }

    'icons'  { Invoke-Step 'dart' @('run', 'flutter_launcher_icons') }
    'splash' { Invoke-Step 'dart' @('run', 'flutter_native_splash:create') }

    'outdated' { Invoke-Step 'flutter' @('pub', 'outdated') }
    'upgrade'  { Invoke-Step 'flutter' @('pub', 'upgrade') }
    'clean'    { Invoke-Step 'flutter' @('clean') }
    'reset'    {
        Invoke-Step 'flutter' @('clean')
        Invoke-Step 'flutter' @('pub', 'get')
    }

    default {
        Write-Host "Không có lệnh '$Command'." -ForegroundColor Red
        Show-Help
        exit 1
    }
}
