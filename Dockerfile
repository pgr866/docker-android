FROM eclipse-temurin:21-jdk-jammy

# Environment configuration: suppress interactive prompts and define core Android SDK paths and emulator settings
ENV DEBIAN_FRONTEND=noninteractive \
	ANDROID_SDK_ROOT=/opt/android \
	ANDROID_AVD_HOME=/data \
	QTWEBENGINE_DISABLE_SANDBOX=1 \
	ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL=10

# Use bash as the default shell for consistent script execution
SHELL ["/bin/bash", "-c"]

# Install system dependencies required for the Android emulator, virtual display, and audio/graphics support
RUN apt-get update && apt-get install -y \
	curl wget unzip bzip2 libdrm-dev libxkbcommon-dev \
	libgbm-dev libasound-dev libnss3 libxcursor1 \
	libpulse-dev libxshmfence-dev xauth xvfb x11vnc \
	fluxbox wmctrl libdbus-glib-1-2 socat virt-manager \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

# Build-time arguments for Android emulator configuration (API level, system image type, architecture, and device profile)
ARG API_LEVEL=36 \
	CMD_LINE_VERSION=14742923_latest \
	IMG_TYPE=google_apis \
	ARCHITECTURE=x86_64 \
	DEVICE_ID=pixel

# Derive runtime environment variables from build args and extend PATH with Android SDK tool directories
ENV PACKAGE_PATH="system-images;android-${API_LEVEL};${IMG_TYPE};${ARCHITECTURE}" \
	API_LEVEL=$API_LEVEL \
	CMD_LINE_VERSION=$CMD_LINE_VERSION \
	DEVICE_ID=$DEVICE_ID \
	ABI=${IMG_TYPE}/${ARCHITECTURE} \
	PATH="$PATH:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/cmdline-tools/tools/bin" \
	LD_LIBRARY_PATH="$ANDROID_SDK_ROOT/emulator/lib64:$ANDROID_SDK_ROOT/emulator/lib64/qt/lib"

# Set working directory for SDK installation and script execution
WORKDIR /opt

# Expose ADB and emulator console ports for external communication with the running emulator
EXPOSE 5554 5555

# Create required Android configuration directories and initialize the repositories config file
RUN mkdir -p /root/.android /data && touch /root/.android/repositories.cfg

# Copy setup scripts into the container, grant execution permissions, and run the SDK installer
COPY scripts/install-sdk.sh /opt/
RUN chmod +x /opt/install-sdk.sh && /opt/install-sdk.sh
COPY scripts/emulator-monitoring.sh scripts/start-emulator.sh /opt/
RUN chmod +x /opt/emulator-monitoring.sh /opt/start-emulator.sh

# Define the emulator startup script as the container entrypoint
ENTRYPOINT ["/opt/start-emulator.sh"]
