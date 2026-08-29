# ---------------------------------------------------------------------------
# HealthMate FE — các lệnh thường dùng.
#
#   make            # xem danh sách lệnh
#   make setup      # cài lần đầu sau khi clone
#   make run        # chạy app trên thiết bị/emulator đang kết nối
#   make check      # chạy đúng bộ kiểm tra mà CI sẽ chạy
#
# Windows chưa có `make`? Dùng bản PowerShell tương đương:
#   .\tool\dev.ps1 <lệnh>      (ví dụ: .\tool\dev.ps1 run-demo)
# ---------------------------------------------------------------------------

FLUTTER ?= flutter
DART    ?= dart
WEB_PORT ?= 5000

.DEFAULT_GOAL := help
.PHONY: help setup get fmt fmt-check analyze test check \
        run run-demo run-web run-web-demo \
        build-apk build-aab build-web build-ios \
        icons splash clean reset adb-reverse doctor outdated upgrade

help: ## Liệt kê tất cả lệnh
	@echo "HealthMate FE — make <lệnh>"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

# --- Khởi tạo -------------------------------------------------------------

setup: ## Cài đặt lần đầu: tạo .env từ .env.example rồi pub get
	@test -f .env || (cp .env.example .env && echo "Đã tạo .env từ .env.example — nhớ điền BASE_URL và GOOGLE_CLIENT_ID.")
	$(FLUTTER) pub get

get: ## Tải dependencies
	$(FLUTTER) pub get

doctor: ## Kiểm tra môi trường Flutter
	$(FLUTTER) doctor -v

# --- Chất lượng code ------------------------------------------------------

fmt: ## Format toàn bộ code Dart
	$(DART) format .

fmt-check: ## Kiểm tra format, fail nếu có file chưa format (dùng trong CI)
	$(DART) format --output=none --set-exit-if-changed .

analyze: ## Phân tích tĩnh
	$(FLUTTER) analyze

test: ## Chạy unit/widget test
	$(FLUTTER) test

check: fmt-check analyze test ## Chạy đủ bộ kiểm tra như CI — chạy trước khi mở PR

# --- Chạy app -------------------------------------------------------------

run: ## Chạy trên thiết bị/emulator đang kết nối (gọi API thật)
	$(FLUTTER) run

run-demo: ## Chạy với dữ liệu giả lập, không cần backend
	$(FLUTTER) run --dart-define=DEMO_MODE=true

run-web: ## Chạy trên Chrome (port cố định để Google OAuth hoạt động)
	$(FLUTTER) run -d chrome --web-port=$(WEB_PORT)

run-web-demo: ## Chạy trên Chrome với dữ liệu giả lập
	$(FLUTTER) run -d chrome --web-port=$(WEB_PORT) --dart-define=DEMO_MODE=true

adb-reverse: ## Trỏ localhost:8080 của máy Android thật về máy tính (dev backend local)
	adb reverse tcp:8080 tcp:8080

# --- Build ----------------------------------------------------------------

build-apk: ## Build APK release
	$(FLUTTER) build apk --release

build-aab: ## Build Android App Bundle (nộp lên Play Store)
	$(FLUTTER) build appbundle --release

build-web: ## Build bản web release vào build/web
	$(FLUTTER) build web --release

build-ios: ## Build iOS release (yêu cầu macOS + Xcode)
	$(FLUTTER) build ios --release

build-demo-apk: ## Build APK demo chạy hoàn toàn bằng mock data
	$(FLUTTER) build apk --release --dart-define=DEMO_MODE=true

build-demo-web: ## Build web demo chạy hoàn toàn bằng mock data
	$(FLUTTER) build web --release --dart-define=DEMO_MODE=true

# --- Assets ---------------------------------------------------------------

icons: ## Sinh lại app icon từ assets/icons/app_logo.png
	$(DART) run flutter_launcher_icons

splash: ## Sinh lại native splash screen
	$(DART) run flutter_native_splash:create

# --- Bảo trì --------------------------------------------------------------

outdated: ## Liệt kê dependency có bản mới
	$(FLUTTER) pub outdated

upgrade: ## Nâng dependency trong phạm vi ràng buộc pubspec
	$(FLUTTER) pub upgrade

clean: ## Xoá build artifacts
	$(FLUTTER) clean

reset: clean get ## clean + pub get (dùng khi build lỗi lạ)
