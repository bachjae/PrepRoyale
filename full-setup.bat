@echo off
echo ========================================
echo   FULL PROJECT SETUP
echo   Installing ALL dependencies
echo ========================================
echo.

cd /d "%~dp0"

echo ========================================
echo STEP 1: Install Firebase Functions Dependencies
echo ========================================
echo.
cd functions
call npm install
if errorlevel 1 (
    echo ERROR: Failed to install npm dependencies
    pause
    exit /b 1
)
echo.
echo SUCCESS: Firebase Functions dependencies installed
echo.

echo ========================================
echo STEP 2: Build Cloud Functions
echo ========================================
echo.
call npm run build
if errorlevel 1 (
    echo ERROR: Failed to build Cloud Functions
    pause
    exit /b 1
)
echo.
echo SUCCESS: Cloud Functions built
echo.

cd ..

echo ========================================
echo STEP 3: Install Flutter Dependencies
echo ========================================
echo.
call flutter pub get
if errorlevel 1 (
    echo ERROR: Failed to install Flutter dependencies
    pause
    exit /b 1
)
echo.
echo SUCCESS: Flutter dependencies installed
echo.

echo ========================================
echo STEP 4: Run Code Generation
echo ========================================
echo.
call dart run build_runner build --delete-conflicting-outputs
if errorlevel 1 (
    echo WARNING: Code generation had issues
)
echo.
echo SUCCESS: Code generation complete
echo.

echo ========================================
echo STEP 5: Flutter Doctor Check
echo ========================================
echo.
flutter doctor
echo.

echo ========================================
echo   SETUP COMPLETE!
echo ========================================
echo.
echo Next steps:
echo   1. Run 'start-emulators.bat' in one terminal
echo   2. Run 'start-app.bat' in another terminal
echo.
echo Or to generate test questions in emulator:
echo   cd functions
echo   node test-generate.js
echo.

pause
