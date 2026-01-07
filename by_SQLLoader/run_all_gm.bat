@echo off
setlocal enabledelayedexpansion

REM Load .env file
if not exist ".env" (
    echo .env file not found!, Creating one...
    goto :create_env_template
) else (
    echo .env file found, continuing...
)

REM Read and set .env variables
for /f "usebackq tokens=1,2 delims==" %%a in (".env") do (
    if not "%%a"=="" if not "%%a:~0,1"=="#" set "%%a=%%b"
)

  
REM without -s for SQLPROMT with host
sqlplus  !DB_USER!/!DB_PASSWORD!@//!DB_HOST!:!DB_PORT!/!SERVICE_NAME! @scripts/output_res.sql
if errorlevel 1 (
    echo DB schema login failed! Check credentials in .env
    pause & exit /b 1
)
REM sqlplus -s !DB_USER!/!DB_PASSWORD!@//!DB_HOST!:!DB_PORT!/!SERVICE_NAME! @scripts/output_res.sql

pause
goto :eof

:create_env_template
echo Creating .env template file...
(
echo # Database Configuration
echo SERVICE_NAME=yash_pdb
echo DB_USER=ashish
echo DB_PASSWORD=ap123
echo.
echo # below bypasses the tns,(then no tnsnames-path setup)
echo DB_PORT=1521
echo DB_HOST=192.168.28.24
) > .env
echo .env file created! Please edit it with your configuration.
pause
goto :eof
