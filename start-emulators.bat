@echo off
echo ========================================
echo   Starting Firebase Emulators
echo ========================================
echo.

cd /d "%~dp0"

echo [1/3] Installing Firebase Functions dependencies...
cd functions
call npm install
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo [2/3] Building Cloud Functions (TypeScript)...
call npm run build
if errorlevel 1 (
    echo ERROR: Failed to build functions
    pause
    exit /b 1
)

echo.
echo [3/3] Starting Firebase Emulators...
echo.
echo Emulator UI will be available at: http://localhost:4000
echo - Auth Emulator:      http://localhost:9099
echo - Firestore Emulator: http://localhost:8080
echo - Database Emulator:  http://localhost:9000
echo - Functions Emulator: http://localhost:5001
echo.
echo Press Ctrl+C to stop emulators
echo.

cd ..
firebase emulators:start

pause
