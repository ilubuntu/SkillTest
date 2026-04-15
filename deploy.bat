@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "OPENCODE_PORT=4096"
set "BACKEND_PORT=8000"
set "EXECUTOR_DIR=%SCRIPT_DIR%\agent_bench\executor"
set "LOG_DIR=%SCRIPT_DIR%\logs"
set "OPENCODE_LOG=%LOG_DIR%\opencode.log"
set "CURRENT_EXECUTOR_LOG_FILE=%LOG_DIR%\current_executor_log"
set "BACKEND_LOG="
set "PYTHON_CMD="
set "AUTO_PAUSE_ON_FAILURE=0"
set "OPENCODE_HTTP_PROXY="
set "OPENCODE_HTTPS_PROXY="
set "OPENCODE_ALL_PROXY="
set "OPENCODE_NO_PROXY="
set "OPENCODE_USE_PROXY=0"

set "ACTION=%~1"
if not defined ACTION (
    set "ACTION=start"
    set "AUTO_PAUSE_ON_FAILURE=1"
)

if /I "%ACTION%"=="start" goto :start_executor
if /I "%ACTION%"=="stop" goto :stop_all
if /I "%ACTION%"=="restart" goto :restart_all
if /I "%ACTION%"=="restart-executor" goto :restart_executor_only
if /I "%ACTION%"=="logs" goto :show_logs
if /I "%ACTION%"=="status" goto :show_status
goto :usage

:info
echo [INFO] %~1
exit /b 0

:warn
echo [WARN] %~1
exit /b 0

:error
echo [ERROR] %~1
exit /b 0

:pause_if_needed
if "%AUTO_PAUSE_ON_FAILURE%"=="1" pause
exit /b 0

:ensure_log_dir
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
exit /b 0

:resolve_python
set "PYTHON_CMD="
where python >nul 2>&1
if not errorlevel 1 (
    set "PYTHON_CMD=python"
    exit /b 0
)
where python3 >nul 2>&1
if not errorlevel 1 (
    set "PYTHON_CMD=python3"
    exit /b 0
)
where py >nul 2>&1
if not errorlevel 1 (
    py -3 -c "import sys" >nul 2>&1
    if not errorlevel 1 (
        set "PYTHON_CMD=py -3"
        exit /b 0
    )
)
exit /b 1

:check_deps
call :info "Checking dependencies..."
set "MISSING=0"

where opencode >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -Command "if (Get-Command opencode -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
    if errorlevel 1 (
        call :error "Missing dependency: opencode. Please install it first: https://opencode.ai"
        set "MISSING=1"
    )
)

call :resolve_python
if errorlevel 1 (
    call :error "Missing dependency: python / python3 / py -3"
    set "MISSING=1"
)

if "%MISSING%"=="1" (
    call :error "Required dependencies are missing."
    exit /b 1
)

call :info "Dependency check passed. Python: %PYTHON_CMD%"
exit /b 0

:resolve_executor_log_file
if defined BACKEND_LOG exit /b 0
if exist "%CURRENT_EXECUTOR_LOG_FILE%" (
    for /f "usebackq delims=" %%I in ("%CURRENT_EXECUTOR_LOG_FILE%") do set "BACKEND_LOG=%%I"
    if defined BACKEND_LOG exit /b 0
)
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "$f = Get-ChildItem -Path '%LOG_DIR%' -Filter 'agent_bench_*.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName; if ($f) { Write-Output $f }"`) do set "BACKEND_LOG=%%I"
exit /b 0

:load_opencode_proxy_config
set "OPENCODE_HTTP_PROXY="
set "OPENCODE_HTTPS_PROXY="
set "OPENCODE_ALL_PROXY="
set "OPENCODE_NO_PROXY="
set "OPENCODE_USE_PROXY=0"
set "AGENTS_CONFIG=%SCRIPT_DIR%\config\agents.yaml"
if not exist "%AGENTS_CONFIG%" exit /b 0

for /f "usebackq tokens=1,* delims==" %%A in (`call %PYTHON_CMD% -c "import sys,yaml; data=yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}; agents=data.get('agents') or []; proxy=next(((agent.get('opencode_proxy') or {}) for agent in agents if isinstance(agent, dict) and isinstance(agent.get('opencode_proxy') or {}, dict) and (agent.get('opencode_proxy') or {})), {}); print('http_proxy=' + str(proxy.get('http_proxy') or '').strip()); print('https_proxy=' + str(proxy.get('https_proxy') or '').strip()); print('all_proxy=' + str(proxy.get('all_proxy') or '').strip()); print('no_proxy=' + str(proxy.get('no_proxy') or '').strip())" "%AGENTS_CONFIG%" 2^>nul`) do (
    if /I "%%A"=="http_proxy" set "OPENCODE_HTTP_PROXY=%%B"
    if /I "%%A"=="https_proxy" set "OPENCODE_HTTPS_PROXY=%%B"
    if /I "%%A"=="all_proxy" set "OPENCODE_ALL_PROXY=%%B"
    if /I "%%A"=="no_proxy" set "OPENCODE_NO_PROXY=%%B"
)
exit /b 0

:select_opencode_network_mode
set "OPENCODE_USE_PROXY=0"
call :info "Checking OpenCode network path..."
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -UseBasicParsing -Uri 'https://models.dev' -TimeoutSec 6 > $null; exit 0 } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 (
    call :info "OpenCode will use direct network access."
    exit /b 0
)

if defined OPENCODE_HTTP_PROXY (
    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { $proxy = New-Object System.Net.WebProxy('http://127.0.0.1:7890'); $req = [System.Net.WebRequest]::Create('https://models.dev'); $req.Proxy = $proxy; $req.Timeout = 6000; $resp = $req.GetResponse(); $resp.Close(); exit 0 } catch { exit 1 }" >nul 2>&1
    if not errorlevel 1 (
        set "OPENCODE_USE_PROXY=1"
        call :info "OpenCode will use proxy network access."
        exit /b 0
    )
)

call :warn "Direct network and proxy preflight both failed; OpenCode will start with direct network as fallback."
exit /b 0

:refresh_executor_log_file
set "BACKEND_LOG="
call :resolve_executor_log_file
exit /b 0

:is_opencode_healthy
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { $content = (Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:%OPENCODE_PORT%/global/health' -TimeoutSec 2).Content; if ($content -match 'healthy') { exit 0 } } catch {}; exit 1" >nul 2>&1
exit /b %errorlevel%

:is_backend_healthy
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:%BACKEND_PORT%/api/health' -TimeoutSec 2 > $null; exit 0 } catch { exit 1 }" >nul 2>&1
exit /b %errorlevel%

:kill_port
set "PORT=%~1"
 powershell -NoProfile -Command "$port=%PORT%; $connections = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique; if ($connections) { foreach ($procId in $connections) { try { Stop-Process -Id $procId -Force -ErrorAction Stop } catch {} }; exit 0 } else { exit 1 }" >nul 2>&1
if not errorlevel 1 (
    call :warn "Port %PORT% is in use. Existing process has been stopped."
    timeout /t 1 /nobreak >nul
)
exit /b 0

:cleanup_opencode_snapshot_locks
powershell -NoProfile -Command "$root = Join-Path $env:USERPROFILE '.local\\share\\opencode\\snapshot'; if (-not (Test-Path $root)) { exit 0 }; $threshold = (Get-Date).AddMinutes(-5); $locks = Get-ChildItem -Path $root -Recurse -Filter 'gc.pid.lock' -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $threshold }; foreach ($lock in $locks) { try { Remove-Item -LiteralPath $lock.FullName -Force -ErrorAction Stop } catch {} }; if ($locks) { exit 0 } else { exit 1 }" >nul 2>&1
if not errorlevel 1 (
    call :warn "Removed stale OpenCode snapshot lock files."
)
exit /b 0

:start_opencode
call :info "Starting OpenCode Server on port %OPENCODE_PORT%..."
call :is_opencode_healthy
if not errorlevel 1 (
    call :info "OpenCode Server is already running."
    exit /b 0
)

call :kill_port %OPENCODE_PORT%
call :cleanup_opencode_snapshot_locks
call :ensure_log_dir
if not exist "%OPENCODE_LOG%" type nul > "%OPENCODE_LOG%"
call :select_opencode_network_mode

if "%OPENCODE_USE_PROXY%"=="1" (
    call :info "OpenCode Server will use proxy environment (NO_PROXY=%OPENCODE_NO_PROXY%)"
    start "" /b cmd /d /c "cd /d ""%SCRIPT_DIR%"" && set http_proxy=%OPENCODE_HTTP_PROXY% && set https_proxy=%OPENCODE_HTTPS_PROXY% && set HTTP_PROXY=%OPENCODE_HTTP_PROXY% && set HTTPS_PROXY=%OPENCODE_HTTPS_PROXY% && set all_proxy=%OPENCODE_ALL_PROXY% && set ALL_PROXY=%OPENCODE_ALL_PROXY% && set no_proxy=%OPENCODE_NO_PROXY% && set NO_PROXY=%OPENCODE_NO_PROXY% && opencode serve --port %OPENCODE_PORT% >> ""%OPENCODE_LOG%"" 2>&1"
 ) else (
    call :info "OpenCode Server will start without proxy environment"
    start "" /b cmd /d /c "cd /d ""%SCRIPT_DIR%"" && opencode serve --port %OPENCODE_PORT% >> ""%OPENCODE_LOG%"" 2>&1"
 )

call :info "Waiting for OpenCode Server..."
for /L %%I in (1,1,90) do (
    call :is_opencode_healthy
    if not errorlevel 1 (
        call :info "OpenCode Server started successfully."
        exit /b 0
    )
    timeout /t 1 /nobreak >nul
)

call :warn "OpenCode Server may not be fully ready yet. Check %OPENCODE_LOG%"
exit /b 0

:install_python_deps
set "REQ=%EXECUTOR_DIR%\requirements.txt"
if not exist "%REQ%" exit /b 0

call :info "Installing Python dependencies..."
call %PYTHON_CMD% -m pip install --break-system-packages -q -r "%REQ%" >nul 2>&1
if errorlevel 1 (
    call %PYTHON_CMD% -m pip install -q -r "%REQ%" >nul 2>&1
)
if errorlevel 1 (
    call :warn "Python dependency installation failed. Please run: %PYTHON_CMD% -m pip install -r ""%REQ%"""
)
exit /b 0

:start_backend
call :info "Starting executor service on port %BACKEND_PORT%..."
call :is_backend_healthy
if not errorlevel 1 (
    call :refresh_executor_log_file
    call :info "Executor service is already running."
    exit /b 0
)

call :kill_port %BACKEND_PORT%
if not defined BACKEND_LOG (
    for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "$logDir = '%LOG_DIR%'; $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'; Write-Output (Join-Path $logDir ('agent_bench_' + $stamp + '.log'))"`) do set "BACKEND_LOG=%%I"
    > "%CURRENT_EXECUTOR_LOG_FILE%" echo %BACKEND_LOG%
)
if not exist "%BACKEND_LOG%" type nul > "%BACKEND_LOG%"

start "" /b cmd /d /c "cd /d ""%SCRIPT_DIR%"" && call %PYTHON_CMD% -X utf8 -u -m agent_bench.executor.main >> ""%BACKEND_LOG%"" 2>&1"

for /L %%I in (1,1,10) do (
    call :is_backend_healthy
    if not errorlevel 1 (
        call :refresh_executor_log_file
        call :info "Executor service started successfully."
        exit /b 0
    )
    timeout /t 1 /nobreak >nul
)

call :refresh_executor_log_file
call :warn "Executor service may not be fully ready yet. Check %BACKEND_LOG%"
exit /b 0

:follow_executor_logs
call :ensure_log_dir
call :refresh_executor_log_file
if not defined BACKEND_LOG (
    call :warn "No executor log file was found."
    call :warn "If the executor was started outside deploy.bat, restart it with deploy.bat restart-executor to create a managed log."
    call :pause_if_needed
    exit /b 1
)
if not exist "%BACKEND_LOG%" type nul > "%BACKEND_LOG%"

echo.
call :info "Following executor log: %BACKEND_LOG%"
call :info "Press Ctrl+C to stop log viewing. To stop services, run: deploy.bat stop"
echo.

powershell -NoProfile -Command "$path='%BACKEND_LOG%'; [Console]::InputEncoding = New-Object System.Text.UTF8Encoding($false); [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false); if (-not (Test-Path $path)) { New-Item -ItemType File -Path $path -Force | Out-Null }; Get-Content -Encoding UTF8 -LiteralPath $path -Tail 80 -Wait | Where-Object { $_ -notmatch 'GET /api/health' -and $_ -notmatch 'GET /api/cloud-api/status' }"
exit /b %errorlevel%

:ensure_executor_ready
call :check_deps
if errorlevel 1 exit /b 1

call :ensure_log_dir
call :load_opencode_proxy_config
call :start_opencode
call :install_python_deps
call :start_backend
call :is_backend_healthy
if errorlevel 1 (
    call :error "Executor failed to start. Check logs and try again."
    if defined BACKEND_LOG call :error "Executor log: %BACKEND_LOG%"
    exit /b 1
)
call :refresh_executor_log_file
exit /b 0

:start_executor
echo.
echo ==========================================
echo   Agent Bench Executor
echo ==========================================
echo.

call :ensure_executor_ready
if errorlevel 1 (
    call :pause_if_needed
    exit /b 1
)

echo.
call :info "Executor is ready."
call :info "Task entry: http://localhost:%BACKEND_PORT%/api/cloud-api/start"
call :info "Local text entry: http://localhost:%BACKEND_PORT%/api/local/start-text"
if defined BACKEND_LOG call :info "Executor log: %BACKEND_LOG%"
echo.

if not defined BACKEND_LOG (
    call :warn "Executor is already running, but no managed log file is available for live viewing."
    call :warn "If you want deploy.bat to manage the log, run: deploy.bat restart-executor"
    if "%AUTO_PAUSE_ON_FAILURE%"=="1" pause
    exit /b 0
)

call :follow_executor_logs
exit /b %errorlevel%

:stop_all
call :info "Stopping all services..."
call :kill_port %OPENCODE_PORT%
call :kill_port %BACKEND_PORT%
call :info "All services have been stopped."
exit /b 0

:show_status
echo.
echo ========== Agent Bench Service Status ==========
echo.
call :is_opencode_healthy
if not errorlevel 1 (
    echo   OpenCode Server : running  http://localhost:%OPENCODE_PORT%
 ) else (
    echo   OpenCode Server : stopped
 )

call :is_backend_healthy
if not errorlevel 1 (
    echo   Executor        : running  http://localhost:%BACKEND_PORT%
 ) else (
    echo   Executor        : stopped
 )
echo.
echo =================================================
exit /b 0

:show_logs
call :follow_executor_logs
exit /b %errorlevel%

:restart_all
call :stop_all
timeout /t 2 /nobreak >nul
call "%~f0" start
exit /b %errorlevel%

:restart_executor_only
call :info "Restarting executor service only..."
call :check_deps
if errorlevel 1 exit /b 1
call :ensure_log_dir
call :load_opencode_proxy_config
call :refresh_executor_log_file
call :kill_port %BACKEND_PORT%
timeout /t 1 /nobreak >nul
call :install_python_deps
call :start_backend
call "%~f0" status
exit /b %errorlevel%

:usage
echo Usage: %~nx0 ^<start^|stop^|restart^|restart-executor^|logs^|status^>
echo.
echo   start             Start executor and wait for cloud-dispatched tasks ^(default when double-clicked^)
echo   stop              Stop OpenCode and executor
echo   restart           Restart OpenCode and executor
echo   restart-executor  Restart executor only
echo   logs              Follow current executor log
echo   status            Show service status
exit /b 1
