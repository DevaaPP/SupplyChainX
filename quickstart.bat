@echo off
title SupplyChainX - Localhost Quick Start
cls
echo =========================================================================
echo    SupplyChainX -- Enterprise Anti-Counterfeiting Quick Start
echo =========================================================================
echo.
echo  [1/3] Starting FastAPI Backend on http://localhost:8000 ...
start "SupplyChainX Backend (Port 8000)" cmd /k "cd /d D:\cs\supplychainx\backend && python run.py"

echo  [2/3] Starting Flutter Web Server on http://localhost:3000 ...
start "SupplyChainX Web Server (Port 3000)" cmd /k "cd /d D:\cs\supplychainx\supplychainx_app && python serve_web.py"

echo.
echo  [3/3] Waiting for servers to initialize...
timeout /t 2 /nobreak >nul

echo  Opening browser at http://localhost:3000 ...
start http://localhost:3000

echo.
echo =========================================================================
echo  LOCAL SERVICES:
echo    * Frontend Web UI:    http://localhost:3000
echo    * Backend API:        http://localhost:8000
echo    * Swagger API Docs:   http://localhost:8000/docs
echo.
echo  DEMO ACCOUNTS (All passwords: demo1234):
echo    * Enterprise Auditor: admin@supply.com       (Full Audit Stream & Telemetry)
echo    * Manufacturer:       manufacturer@supply.com (Genesis batch registration)
echo    * Distributor:        distributor@supply.com  (Mandatory Scan to Accept)
echo    * Warehouse:          warehouse@supply.com    (Mandatory Scan to Intake)
echo    * Retailer:           retailer@supply.com     (Mandatory Scan to Sell)
echo    * Customer:           customer@supply.com     (Verify Provenance)
echo =========================================================================
echo.
pause

