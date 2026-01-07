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


REM --- Schema Login ---
sqlplus -s -L !DB_USER!/!DB_PASSWORD!@//!DB_HOST!:!DB_PORT!/!SERVICE_NAME! @scripts/test_login.sql 
if errorlevel 1 (
    echo DB schema login failed! Check credentials in .env
    pause & exit /b 1
)

REM Creation of tables and objects
sqlplus -s !DB_USER!/!DB_PASSWORD!@//!DB_HOST!:!DB_PORT!/!SERVICE_NAME! @scripts/create_db_obj.sql

REM Ensuring dir exists
if not exist "logs" mkdir logs
if not exist "logs\bads" mkdir logs\bads


REM Run SQL*Loader for each control file
echo .
echo -----  Running SQL*Loader...
sqlldr !DB_USER!/!DB_PASSWORD!@//!DB_HOST!:!DB_PORT!/!SERVICE_NAME! control=ctls/employees.ctl log=logs/employees.log bad=logs/bads/employees.bad silent=feedback >nul
echo employees.ctl loaded.
sqlldr !DB_USER!/!DB_PASSWORD!@//!DB_HOST!:!DB_PORT!/!SERVICE_NAME! control=ctls/projects.ctl log=logs/projects.log bad=logs/bads/projects.bad silent=feedback >nul
echo projects.ctl loaded.
sqlldr !DB_USER!/!DB_PASSWORD!@//!DB_HOST!:!DB_PORT!/!SERVICE_NAME! control=ctls/timesheets.ctl log=logs/timesheets.log  bad=logs/bads/timesheets.bad silent=feedback >nul
echo timesheets.ctl loaded.
echo .
echo -----  All CTL_Data Re-loaded.
echo -----------------------------------------------------------
pause

sqlplus  !DB_USER!/!DB_PASSWORD!@//!DB_HOST!:!DB_PORT!/!SERVICE_NAME! @scripts/output_res.sql
REM without -s for SQLPROMT with host
@REM sqlplus  !DB_USER!/!DB_PASSWORD!@//!DB_HOST!:!DB_PORT!/!SERVICE_NAME! @scripts/queries.sql scripts/queries.sql

REM sqlplus -s !DB_USER!/!DB_PASSWORD!@//!DB_HOST!:!DB_PORT!/!SERVICE_NAME! @scripts/queries.sql

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
goto :eof

pause