# Source this file from any working directory in the cloud environment.
export PATH="/workspace/toolchains/flutter/bin:/workspace/toolchains/android-sdk/platform-tools:$PATH"
export ANDROID_HOME=/workspace/toolchains/android-sdk
export ANDROID_SDK_ROOT=/workspace/toolchains/android-sdk
export ANDROID_USER_HOME=/workspace/toolchains/android-user
export PUB_CACHE=/workspace/toolchains/pub-cache
export GRADLE_USER_HOME=/workspace/toolchains/gradle
export XDG_CONFIG_HOME=/workspace/toolchains/config
export XDG_CACHE_HOME=/workspace/toolchains/cache
export FLUTTER_SUPPRESS_ANALYTICS=true
export DART_SUPPRESS_ANALYTICS=true
export JAVA_HOME=/workspace/toolchains/jdk
export PATH="$JAVA_HOME/bin:$PATH"
export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=/etc/ssl/certs/java/cacerts"
