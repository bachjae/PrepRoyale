@echo off
echo ========================================
echo   Deploy Cloud Functions to Production
echo ========================================
echo.

cd /d "%~dp0"

echo WARNING: This will deploy functions to PRODUCTION Firebase!
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause > nul

echo.
echo [1/2] Building Cloud Functions...
cd functions
call npm install
call npm run build
if errorlevel 1 (
    echo ERROR: Failed to build functions
    pause
    exit /b 1
)

cd ..

echo.
echo [2/2] Deploying to Firebase...
firebase deploy --only functions

if errorlevel 1 (
    echo ERROR: Deployment failed
    pause
    exit /b 1
)

echo.
echo ========================================
echo   DEPLOYMENT COMPLETE!
echo ========================================
echo.

pause
