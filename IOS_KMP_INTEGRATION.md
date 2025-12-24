# iOS KMP Framework Integration Guide

This guide explains how to integrate the Kotlin Multiplatform (KMP) shared framework into the iOS BurnerApp.

## Overview

The shared KMP framework provides cross-platform business logic, data models, and repositories that can be used by both iOS and Android. This eliminates code duplication and ensures consistency across platforms.

## What's Included in the Shared Framework

### Data Models
- `Event` - Event data with computed properties (isPast, hasStarted, distanceFrom, etc.)
- `Ticket` - Ticket management with status tracking
- `User` - User profile and authentication
- `Venue` - Venue information
- `Bookmark` - Saved events
- `Tag` - Event genres/categories
- `Coordinate` - Geographic coordinates

### Repositories
- `EventRepository` - Event fetching, filtering, and search
- `TicketRepository` - Ticket management and status tracking
- `BookmarkRepository` - Bookmark CRUD operations
- `UserRepository` - User profile operations
- `TagRepository` - Tag/genre management

### Business Logic
- `EventFilteringUseCase` - Filter events (featured, nearby, by genre)
- `SearchUseCase` - Search and sort events
- `TicketStatusTracker` - Track ticket status and history

### Services
- `AuthService` - Authentication (sign in, sign up, password reset)

### Utilities
- `DateUtils` - Date formatting and calculations
- `GeoUtils` - Distance calculations (haversine formula)
- `PriceUtils` - Price formatting and conversions

## Integration Steps

### Step 1: Build the Shared Framework

The framework needs to be built for iOS simulator and device architectures:

```bash
# For iOS Simulator (ARM64 - Apple Silicon Macs)
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64

# For iOS Simulator (x64 - Intel Macs)
./gradlew :shared:linkDebugFrameworkIosX64

# For iOS Device
./gradlew :shared:linkDebugFrameworkIosArm64
```

The framework will be built to:
- `shared/build/bin/iosSimulatorArm64/debugFramework/Shared.framework`
- `shared/build/bin/iosX64/debugFramework/Shared.framework`
- `shared/build/bin/iosArm64/debugFramework/Shared.framework`

**Note:** The `build_shared_framework.sh` script automates this process.

### Step 2: Link the Framework in Xcode

1. Open `burner.xcodeproj` in Xcode
2. Select the `burner` target
3. Go to "Build Phases" > Verify the "Run Script" phase exists that executes `build_shared_framework.sh`
4. Go to "General" > "Frameworks, Libraries, and Embedded Content"
5. Add the Shared.framework and set "Embed" to "Embed & Sign"

### Step 3: Initialize KMP in AppState

Update `burner/App/AppState.swift` to initialize the KMP Supabase manager.

See full documentation in the file for more details.
