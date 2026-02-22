@echo off
setlocal enabledelayedexpansion

:: Set working directory to the script's location
cd /d "%~dp0"

:: Path Configuration
set "SCRCPY_DIR=%~dp0scrcpy"
set "ZIP_FILE=%~dp0scrcpy.zip"

echo [1/4] Checking Docker status...

:: Check if Docker is installed
where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed. Redirecting to download page...
    start https://www.docker.com/products/docker-desktop/
    exit /b
)

:: Check if Docker Engine is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Docker is not running. Attempting to start Docker Desktop...
    start "" "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    
    echo [.] Waiting for Docker to initialize...
    :wait_docker
    docker info >nul 2>&1
    if %errorlevel% neq 0 (
        set /p="." <nul
        timeout /t 3 /nobreak >nul
        goto wait_docker
    )
    echo.
    echo [OK] Docker is now ready.
)

echo [2/4] Preparing scrcpy in %SCRCPY_DIR%...

:: Check if scrcpy already exists
if not exist "%SCRCPY_DIR%\scrcpy.exe" (
    echo scrcpy not found. Fetching latest release...
    for /f "tokens=*" %%i in ('curl -s https://api.github.com/repos/Genymobile/scrcpy/releases/latest ^| findstr "browser_download_url.*win64.*zip"') do (
        set "RAW_URL=%%i"
    )
    set "DOWNLOAD_URL=!RAW_URL:*https=https!"
    set "DOWNLOAD_URL=!DOWNLOAD_URL:"=!"
    
    echo Downloading: !DOWNLOAD_URL!
    curl -L -o "%ZIP_FILE%" "!DOWNLOAD_URL!"
    
    echo Extracting files...
    if exist "%SCRCPY_DIR%" rd /s /q "%SCRCPY_DIR%"
    mkdir "%SCRCPY_DIR%"
    tar -xf "%ZIP_FILE%" -C "%SCRCPY_DIR%" --strip-components=1
    del "%ZIP_FILE%"
    echo [OK] scrcpy extracted successfully.
) else (
    echo [OK] scrcpy already exists.
)

echo [3/4] Starting Android Emulator...

:: Kill any local adb instances to prevent port conflicts
taskkill /F /IM adb.exe /T >nul 2>&1

:: Deploy the containerized emulator in detached mode
docker compose up --build -d

echo [4/4] Waiting for Android UI to be ready...

:: Polling loop to ensure the ADB daemon is initialized and the device is reachable
:wait_adb
"%SCRCPY_DIR%\adb.exe" devices | findstr "\<device\>" > nul 2>&1
if %errorlevel% neq 0 (
    timeout /t 2 /nobreak > nul
    goto wait_adb
)

:: Wait until the system property confirms boot is 100% complete
:wait_final
docker exec android-emulator adb shell getprop sys.boot_completed | findstr "1" > nul 2>&1
if %errorlevel% neq 0 (
    timeout /t 2 /nobreak > nul
    goto wait_final
)

timeout /t 5 /nobreak > nul

echo [DONE] Launching scrcpy...

:: Launch scrcpy
start /b "" "%SCRCPY_DIR%\scrcpy.exe" --video-bit-rate=16M --max-fps=30 --video-codec=h264 --turn-screen-off --stay-awake --audio-buffer=40 --window-title "Android"
