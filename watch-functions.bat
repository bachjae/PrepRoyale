@echo off
echo ========================================
echo   Watch Mode for Cloud Functions
echo   Auto-rebuilds on file changes
echo ========================================
echo.

cd /d "%~dp0"

echo Starting TypeScript watch mode...
echo Press Ctrl+C to stop
echo.

cd functions
call npm install
call npm run build:watch

pause
