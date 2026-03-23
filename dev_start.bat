@echo off
echo [1] Ket noi adb reverse...
adb reverse tcp:8080 tcp:8080
if %errorlevel% neq 0 (
    echo [!] Ket noi that bai. Kiem tra USB va Android Debugging.
    pause
    exit /b 1
)
echo [OK] adb reverse tcp:8080 tcp:8080 thanh cong.
echo.
echo [2] Mo app tren dien thoai, sau do chay flutter run trong VSCode.
pause
