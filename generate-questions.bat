@echo off
echo ========================================
echo   Generate Test Questions (Emulator)
echo ========================================
echo.

cd /d "%~dp0"

echo IMPORTANT: Make sure Firebase Emulators are running!
echo If not, run start-emulators.bat first.
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause > nul

cd functions

echo.
echo [1/2] Installing dependencies (if needed)...
call npm install
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo [2/2] Generating test questions...
echo This will add sample questions to the emulator database.
echo.

node test-generate.js

if errorlevel 1 (
    echo ERROR: Failed to generate questions
    pause
    exit /b 1
)

echo.
echo ========================================
echo   QUESTIONS GENERATED!
echo ========================================
echo.
echo View them in Firestore Emulator UI:
echo   http://localhost:4000/firestore
echo.

cd ..
pause
