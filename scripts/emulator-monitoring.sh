#!/bin/bash
set -e

# Helper to output structured logs
write_log() {
  echo "{ \"type\": \"$1\", \"value\": \"$2\" }"
}

# Wrapper for state updates
update_state() {
  write_log "state-update" "$1"
}

# Apply UI performance optimizations
disable_animation() {
  echo "Applying: Disable animations..."
  adb shell "settings put global window_animation_scale 0.0; \
             settings put global transition_animation_scale 0.0; \
             settings put global animator_duration_scale 0.0"
}

# Bypass Android hidden API restrictions
hidden_policy() {
  echo "Applying: Hidden API policy..."
  adb shell "settings put global hidden_api_policy_pre_p_apps 1; \
             settings put global hidden_api_policy_p_apps 1; \
             settings put global hidden_api_policy 1"
}

# Main boot monitoring sequence
wait_for_boot() {
  update_state "ANDROID_BOOTING"

  echo "Waiting for ADB device..."
  adb wait-for-device

  # Polling for system boot completion
  TIMEOUT=300
  COUNTER=0
  
  until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do
    if [ $COUNTER -ge $TIMEOUT ]; then
      echo "Error: Boot timeout reached ($TIMEOUTs)."
      exit 1
    fi
    sleep 5
    ((COUNTER+=5))
  done

  # Apply post-boot configurations based on environment variables
  [ "$DISABLE_ANIMATION" = "true" ] && disable_animation
  [ "$DISABLE_HIDDEN_POLICY" = "true" ] && hidden_policy

  update_state "ANDROID_READY"
}
