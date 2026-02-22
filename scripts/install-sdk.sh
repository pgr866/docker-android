#!/bin/bash
set -e

# Download and configure essential Android command-line tools to initialize the SDK environment
echo "Installing the Android SDK, platform tools and emulator..."
wget https://dl.google.com/android/repository/commandlinetools-linux-${CMD_LINE_VERSION}.zip -P /tmp && \
mkdir -p $ANDROID_SDK_ROOT/cmdline-tools/ && \
unzip -d $ANDROID_SDK_ROOT/cmdline-tools/ /tmp/commandlinetools-linux-${CMD_LINE_VERSION}.zip && \
mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools/ $ANDROID_SDK_ROOT/cmdline-tools/tools/ && \
rm /tmp/commandlinetools-linux-${CMD_LINE_VERSION}.zip && \

# Auto-accept SDK licenses and deploy the required system image, platform-tools, and emulator binaries
yes | sdkmanager --licenses
sdkmanager --install "platform-tools" "platforms;android-${API_LEVEL}" "${PACKAGE_PATH}"
