@echo off
echo ========================================
echo   Starting Flutter App
echo ========================================
echo.

cd /d "%~dp0"

echo [1/4] Checking Flutter installation...
flutter doctor --version
if errorlevel 1 (
    echo ERROR: Flutter not found. Please install Flutter first.
    pause
    exit /b 1
)

echo.
echo [2/4] Installing Flutter dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to install Flutter dependencies
    pause
    exit /b 1
)

echo.
echo [3/4] Running code generation (Riverpod/JSON)...
call dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 (
    echo WARNING: Code generation had issues, continuing anyway...
)

echo.
echo [4/4] Starting Flutter app...
echo.
echo IMPORTANT: Make sure Firebase Emulators are running!
echo Run start-emulators.bat in a separate terminal window.
echo.
echo Available devices:
flutter devices
echo.

echo Starting app on connected device...
flutter run

pause
