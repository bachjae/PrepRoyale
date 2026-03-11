@echo off
echo ========================================
echo   Building Release APK
echo ========================================
echo.

cd /d "%~dp0"

echo [1/5] Installing Flutter dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo [2/5] Running code generation...
call dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 (
    echo WARNING: Code generation had issues, continuing...
)

echo.
echo [3/5] Cleaning previous builds...
call flutter clean
call flutter pub get

echo.
echo [4/5] Running Dart analyzer...
call dart analyze
if errorlevel 1 (
    echo WARNING: Analysis found issues, continuing anyway...
)

echo.
echo [5/5] Building release APK...
echo This may take several minutes...
echo.

call flutter build apk --release

if errorlevel 1 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo   BUILD SUCCESSFUL!
echo ========================================
echo.
echo APK location:
echo   build\app\outputs\flutter-apk\app-release.apk
echo.
echo File size:
dir /s build\app\outputs\flutter-apk\app-release.apk | find "app-release.apk"
echo.

pause
