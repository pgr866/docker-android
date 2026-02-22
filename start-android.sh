#!/bin/sh

# Set working directory to the script's location
cd "$(dirname "$0")"

# Path Configuration
SCRCPY_DIR="$(pwd)/scrcpy"
TAR_FILE="$(pwd)/scrcpy.tar.gz"

echo "[1/4] Checking Docker Engine status..."

# Check if Docker is installed
if ! command -v docker > /dev/null 2>&1; then
    echo "[ERROR] Docker Engine is not installed. Redirecting to installation page..."
    if command -v xdg-open > /dev/null 2>&1; then
        xdg-open https://docs.docker.com/engine/install/
    elif command -v open > /dev/null 2>&1; then
        open https://docs.docker.com/engine/install/
    fi
    exit 1
fi

# Check if Docker Engine is running
if ! sudo docker info > /dev/null 2>&1; then
    echo "[!] Docker Engine is not running. Starting it now..."
    sudo systemctl start docker
fi

# Wait for Docker to be fully ready
echo "[.] Waiting for Docker Engine to initialize..."
while ! sudo docker info > /dev/null 2>&1; do
    printf "."
    sleep 3
done

echo ""
echo "[OK] Docker Engine is now ready."

echo [2/4] Preparing scrcpy in $SCRCPY_DIR...

# Check if scrcpy already exists
if [ ! -f "$SCRCPY_DIR/scrcpy" ]; then
    echo scrcpy not found. Fetching latest release...
    
    # Download scrcpy Linux x86_64 v3.3.4
    DOWNLOAD_URL="https://github.com/Genymobile/scrcpy/releases/download/v3.3.4/scrcpy-linux-x86_64-v3.3.4.tar.gz"
    EXPECTED_SHA256="0305d98c06178c67e12427bbf340c436d0d58c9e2a39bf9ffbbf8f54d7ef95a5"
    
    echo Downloading: $DOWNLOAD_URL
    curl -L -o "$TAR_FILE" "$DOWNLOAD_URL"
    
    # Verify SHA256 checksum
    if command -v sha256sum > /dev/null 2>&1; then
        ACTUAL_SHA256=$(sha256sum "$TAR_FILE" | cut -d' ' -f1)
        if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
            echo [ERROR] SHA256 checksum mismatch. Expected: $EXPECTED_SHA256, Got: $ACTUAL_SHA256
            rm -f "$TAR_FILE"
            exit 1
        fi
    fi
    
    echo Extracting files...
    rm -rf "$SCRCPY_DIR"
    mkdir -p "$SCRCPY_DIR"
    tar -xf "$TAR_FILE" -C "$SCRCPY_DIR" --strip-components=1
    rm -f "$TAR_FILE"
    chmod +x "$SCRCPY_DIR/scrcpy" "$SCRCPY_DIR/adb" 2>/dev/null || true
    echo [OK] scrcpy extracted successfully.
else
    echo [OK] scrcpy already exists.
fi

echo [3/4] Starting Android Emulator...

# Kill any local adb instances to prevent port conflicts
pkill -f "adb" 2>/dev/null || true

# Deploy the containerized emulator in detached mode
sudo docker compose up --build -d

echo [4/4] Waiting for Android UI to be ready...

# Polling loop to ensure the ADB daemon is initialized and the device is reachable
while ! "$SCRCPY_DIR/adb" devices | grep -q "device$"; do
    sleep 2
done

# Wait until the system property confirms boot is 100% complete
while [ "$(sudo docker exec android-emulator adb shell getprop sys.boot_completed 2>/dev/null)" != "1" ]; do
    sleep 2
done

sleep 5

echo [DONE] Launching scrcpy...

# Launch scrcpy
"$SCRCPY_DIR/scrcpy" --video-bit-rate=16M --max-fps=30 --video-codec=h264 --turn-screen-off --stay-awake --audio-buffer=40 --window-title "Android" &
