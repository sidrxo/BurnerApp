#!/bin/bash

set -e

# Determine build configuration
CONFIGURATION=${CONFIGURATION:-Debug}

# Set up paths
PROJECT_DIR="$SRCROOT"
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi

echo "Building Shared framework for iOS..."
echo "Configuration: $CONFIGURATION"

cd "$PROJECT_DIR"

# Determine which framework to build based on the target architecture
if [ "$PLATFORM_NAME" = "iphonesimulator" ]; then
    if [ "$ARCHS" = "arm64" ]; then
        FRAMEWORK_TARGET="linkDebugFrameworkIosSimulatorArm64"
        FRAMEWORK_PATH="shared/build/bin/iosSimulatorArm64/debugFramework/Shared.framework"
    else
        FRAMEWORK_TARGET="linkDebugFrameworkIosX64"
        FRAMEWORK_PATH="shared/build/bin/iosX64/debugFramework/Shared.framework"
    fi
else
    # Device build
    FRAMEWORK_TARGET="linkDebugFrameworkIosArm64"
    FRAMEWORK_PATH="shared/build/bin/iosArm64/debugFramework/Shared.framework"
fi

# Build the framework
echo "Building $FRAMEWORK_TARGET..."
./gradlew :shared:$FRAMEWORK_TARGET

# Verify the framework was built
if [ -d "$FRAMEWORK_PATH" ]; then
    echo "✅ Framework built successfully at: $FRAMEWORK_PATH"
else
    echo "❌ Framework not found at expected path: $FRAMEWORK_PATH"
    exit 1
fi
