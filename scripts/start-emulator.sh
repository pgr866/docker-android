#!/bin/bash
set -e

# Load monitoring functions and status handlers
source ./emulator-monitoring.sh

# Start ADB daemon in the background listening on all interfaces
echo "Starting ADB server..."
adb -a -P 5037 server nodaemon &

# Bridge Android console and ADB ports to the container network interface
# Use reuseaddr to ensure stability across container restarts
echo "Initializing network port forwarding (Socat)..."
LOCAL_IP=$(ip addr list eth0 | grep "inet " | cut -d' ' -f6 | cut -d/ -f1)
echo "Initializing network port forwarding on IP: $LOCAL_IP"
socat tcp-listen:5554,bind="$LOCAL_IP",reuseaddr,fork tcp:127.0.0.1:5554 &
socat tcp-listen:5555,bind="$LOCAL_IP",reuseaddr,fork tcp:127.0.0.1:5555 &

# Verify if the Android Virtual Device already exists; create and configure if missing
if ! avdmanager list avd | grep -q "android"; then
    echo "Creating new AVD: $PACKAGE_PATH..."
    echo no | avdmanager create avd --force --name android --abi "$ABI" --package "$PACKAGE_PATH" --device "$DEVICE_ID"
    echo "Applying display settings (${WIDTH}x${HEIGHT}) and density (${DENSITY})..."
    {
        echo "hw.lcd.width=${WIDTH:-720}"
        echo "hw.lcd.height=${HEIGHT:-1280}"
        echo "hw.lcd.density=${DENSITY:-320}"
    } >> /data/android.avd/config.ini
fi

# Track the boot sequence asynchronously to update container health status
wait_for_boot &

# Launch the emulator with software rendering (SwiftShader) and headless flags
# Environment variables MEMORY and CORES are sourced directly from Docker Compose
echo "Launching Android Emulator (Memory: ${MEMORY}MB, Cores: ${CORES})..."
emulator \
  -avd android \
  -port 5554 \
  -gpu swiftshader_indirect \
  -memory "${MEMORY:-6144}" \
  -cores "${CORES:-3}" \
  -no-boot-anim \
  -skip-adb-auth \
  -no-window \
  -no-snapshot \
  -ranchu || update_state "ANDROID_STOPPED"
