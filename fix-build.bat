@echo off
echo ========================================
echo   Android Build Fix for Windows
echo ========================================
echo.
echo This script will:
echo 1. Stop Gradle daemons
echo 2. Clean build directories
echo 3. Clear Flutter cache
echo 4. Rebuild the project
echo.
echo IMPORTANT: Close Android Studio / VS Code before running this!
echo.
pause

cd /d "%~dp0"

echo [Step 1/6] Stopping Gradle daemons...
cd android
call gradlew.bat --stop
if errorlevel 1 (
    echo WARNING: Gradle stop failed, continuing anyway...
)
cd ..
echo.

echo [Step 2/6] Cleaning Flutter...
call flutter clean
if errorlevel 1 (
    echo ERROR: Flutter clean failed
    pause
    exit /b 1
)
echo.

echo [Step 3/6] Deleting build directories...
if exist "build" (
    echo Deleting build folder...
    rmdir /s /q "build" 2>nul
    timeout /t 2 /nobreak >nul
)
if exist "android\.gradle" (
    echo Deleting android\.gradle folder...
    rmdir /s /q "android\.gradle" 2>nul
    timeout /t 2 /nobreak >nul
)
if exist ".dart_tool" (
    echo Deleting .dart_tool folder...
    rmdir /s /q ".dart_tool" 2>nul
    timeout /t 2 /nobreak >nul
)
echo.

echo [Step 4/6] Getting Flutter packages...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Flutter pub get failed
    pause
    exit /b 1
)
echo.

echo [Step 5/6] Running build_runner (code generation)...
call dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 (
    echo WARNING: Build runner failed, continuing...
)
echo.

echo [Step 6/6] Testing Android build...
call flutter build apk --debug
if errorlevel 1 (
    echo.
    echo ========================================
    echo   BUILD FAILED
    echo ========================================
    echo.
    echo If you see file locking errors:
    echo 1. Pause OneDrive sync on this folder
    echo 2. Temporarily disable antivirus
    echo 3. Close all IDEs and editors
    echo 4. Run this script again
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo   BUILD SUCCESSFUL!
echo ========================================
echo.
echo You can now run: flutter run
echo.
pause
