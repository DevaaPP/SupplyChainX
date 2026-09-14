@echo off
setlocal enabledelayedexpansion
title SupplyChainX - Cryptographic Supply Chain Quick Start
cls

echo =========================================================================
echo    SupplyChainX -- Cryptographic Anti-Counterfeiting Platform
echo =========================================================================
echo.

:: 1. Verify Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python is not detected in your PATH. Please install Python 3.10+.
    pause
    exit /b 1
)

:: 2. Resolve root directory dynamically
set "ROOT_DIR=%~dp0"
if "%ROOT_DIR:~-1%"=="\" set "ROOT_DIR=%ROOT_DIR:~0,-1%"

:: 3. Kill any lingering processes on ports 3000 and 8000
echo  [1/4] Checking and clearing ports 3000 and 8000...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":3000" ^| findstr "LISTENING"') do (
    taskkill /f /pid %%a >nul 2>&1
)
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8000" ^| findstr "LISTENING"') do (
    taskkill /f /pid %%a >nul 2>&1
)

:: 4. Verify web build directory exists
if not exist "%ROOT_DIR%\supplychainx_app\build\web\index.html" (
    echo.
    echo  [BUILD NEEDED] Web production bundle not found. Building now...
    cd /d "%ROOT_DIR%\supplychainx_app"
    call flutter build web
    if %errorlevel% neq 0 (
        echo [ERROR] Flutter web build failed.
        pause
        exit /b 1
    )
)

:: 5. Launch FastAPI Backend
echo  [2/4] Launching FastAPI Backend on http://localhost:8000 ...
start "SupplyChainX Backend (Port 8000)" cmd /k "cd /d "%ROOT_DIR%\backend" && python run.py"

:: 6. Launch Flutter Web Server (with zero-cache headers)
echo  [3/4] Launching Flutter Web Server on http://localhost:3000 ...
start "SupplyChainX Web Server (Port 3000)" cmd /k "cd /d "%ROOT_DIR%\supplychainx_app" && python serve_web.py"

:: 7. Wait and launch browser
echo  [4/4] Initializing services and launching browser...
timeout /t 3 /nobreak >nul
start http://localhost:3000

echo.
echo =========================================================================
echo  SERVICES ONLINE:
echo    * Frontend Web UI:    http://localhost:3000
echo    * Backend REST API:   http://localhost:8000
echo    * Swagger API Docs:   http://localhost:8000/docs
echo    * Release Android APK: supplychainx_app\build\app\outputs\flutter-apk\app-release.apk
echo.
echo  SECURITY & ANTI-TAMPER POLICY:
echo    * Manual Entry:       COMPLETELY DISABLED (prevents fake serial acceptance)
echo    * Random Input:       STRICTLY REJECTED (no false-positive substring matches)
echo    * Custody Handover:   Protected by Master Public Key + Role Private Keys
echo.
echo  DEMO ACCOUNTS (All passwords: demo1234):
echo    * Enterprise Auditor: admin@supply.com        (Full audit stream & threat radar)
echo    * Manufacturer:       manufacturer@supply.com (Genesis batch creation & QR pass)
echo    * Distributor:        distributor@supply.com  (Optical QR scan with Dist Private Key)
echo    * Warehouse:          warehouse@supply.com    (Optical QR scan with WH Private Key)
echo    * Retailer:           retailer@supply.com     (POS checkout & Retail Private Key)
echo    * Customer:           customer@supply.com     (Provenance inspection & tamper scan)
echo =========================================================================
echo.
echo Press any key to exit this launcher window (servers remain running).
pause >nul

