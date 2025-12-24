# iOS KMP Integration Guide

This document explains how the iOS app integrates with the Kotlin Multiplatform shared framework.

## Overview

The BurnerApp iOS application now uses a Kotlin Multiplatform (KMP) shared framework for:
- **Models**: Event, Ticket, User, Bookmark, Tag, Venue, Coordinate
- **Repositories**: EventRepository, TicketRepository, UserRepository, BookmarkRepository, TagRepository
- **Services**: AuthService
- **Business Logic**: EventFilteringUseCase, SearchUseCase, TicketStatusTracker
- **Utilities**: DateUtils, PriceUtils, GeoUtils

## Project Structure

```
BurnerApp/
├── shared/                          # KMP shared module
│   ├── src/
│   │   ├── commonMain/kotlin/       # Shared Kotlin code
│   │   ├── androidMain/kotlin/      # Android-specific code
│   │   └── iosMain/kotlin/          # iOS-specific code
│   └── build.gradle.kts             # Shared module build config
├── burner/                          # iOS app
│   ├── App/
│   │   ├── AppState.swift           # Initializes KMP framework
│   │   └── AppExports.swift         # Re-exports Shared framework
│   └── Extensions/
│       └── SharedExtensions.swift   # Swift extensions for KMP types
└── burner.xcodeproj/                # Xcode project
```

## Build Process

### Automatic Framework Building

The Xcode project includes a build script phase that automatically builds the appropriate KMP framework based on the target architecture:

- **iOS Simulator (ARM64)**: `linkDebugFrameworkIosSimulatorArm64`
- **iOS Simulator (x64)**: `linkDebugFrameworkIosX64`
- **iOS Device**: `linkDebugFrameworkIosArm64`

The build script runs before the iOS app compiles, ensuring the framework is always up-to-date.

### Manual Framework Building

To manually build the framework:

```bash
# For iOS Simulator (ARM64 - M1/M2 Macs)
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64

# For iOS Simulator (x64 - Intel Macs)
./gradlew :shared:linkDebugFrameworkIosX64

# For iOS Device
./gradlew :shared:linkDebugFrameworkIosArm64

# Build all iOS frameworks
./gradlew :shared:linkDebugFrameworkIosArm64 :shared:linkDebugFrameworkIosSimulatorArm64
```

## Usage in Swift

### Initialization

The shared framework is initialized in `AppState.swift`:

```swift
import Shared

init() {
    // Initialize KMP with Supabase credentials
    let url = "https://lsqlgyyugysvhvxtssik.supabase.co"
    let key = "sb_publishable_..."
    KmpHelper.shared.initialize(url: url, key: key)

    // Get repository instances
    self.authService = KmpHelper.shared.getAuthService()
    self.eventRepository = KmpHelper.shared.getEventRepository()
    self.ticketRepository = KmpHelper.shared.getTicketRepository()
    self.bookmarkRepository = KmpHelper.shared.getBookmarkRepository()
    self.userRepository = KmpHelper.shared.getUserRepository()
}
```

### Using KMP Types

Thanks to `@_exported import Shared` in `AppExports.swift`, KMP types are available throughout the app:

```swift
// No need to import Shared explicitly
let event: Event = ...
let ticket: Ticket = ...
```

### Repository Operations

```swift
// Fetch events
let events = try await eventRepository.fetchEvents(
    sinceDate: Kotlinx_datetimeInstant.now(),
    page: 1,
    pageSize: 20
)

// Search events
let results = try await eventRepository.searchEvents(
    query: "concert",
    sortBy: SearchSortOption.date,
    userLatitude: 37.7749,
    userLongitude: -122.4194
)

// Get user tickets
let tickets = try await ticketRepository.fetchUserTickets(userId: userId)

// Authenticate
let success = try await authService.signInWithEmail(
    email: "user@example.com",
    password: "password"
)
```

### Working with Dates

KMP uses `kotlinx.datetime.Instant` and stores dates as ISO8601 strings. Swift extensions provide easy conversion:

```swift
// KMP Event has:
// - startTime: String? (ISO8601)
// - startInstant: Instant? (computed)
// - isPast: Boolean (computed)

// Use Swift extensions:
let event: Event = ...
let startDate: Date? = event.startDate  // Converted to Swift Date
let isPast: Bool = event.isPast         // Direct from KMP
```

### Handling Async Operations

KMP suspend functions are exposed as Swift async functions:

```swift
Task {
    do {
        let events = try await eventRepository.getAllEvents()
        // Handle success
    } catch {
        // Handle error
        print("Error: \(error)")
    }
}
```

## Swift Extensions

The `SharedExtensions.swift` file provides convenient Swift-specific functionality:

- **Event extensions**: `startDate`, `endDate`, `location`, `formattedPrice`
- **Ticket extensions**: `purchaseDateSwift`, `isActive`, `isConfirmed`
- **User extensions**: `createdAtDate`, `lastLoginAtDate`
- **Bookmark extensions**: `bookmarkedAtDate`

## Architecture Benefits

### Code Sharing
- Business logic shared between iOS and Android
- Single source of truth for data models
- Consistent API behavior across platforms

### Type Safety
- Compile-time type checking
- Shared data models ensure consistency
- Reduced runtime errors

### Maintainability
- Update logic once for both platforms
- Easier to add features
- Centralized testing

## Troubleshooting

### Framework Not Found
If you see "Framework not found Shared":
1. Clean build folder (Cmd+Shift+K)
2. Rebuild project (Cmd+B)
3. Manually run: `./gradlew :shared:linkDebugFrameworkIosSimulatorArm64`

### Date Conversion Issues
Use the Swift extensions in `SharedExtensions.swift` for date conversions. The KMP framework uses ISO8601 strings internally.

### Build Script Errors
If the build script fails:
1. Ensure Gradle wrapper is executable: `chmod +x gradlew`
2. Check Java version: `java -version` (should be Java 17+)
3. Try building manually to see detailed errors

## Next Steps

1. **Migration**: Continue migrating iOS-specific repository code to use KMP repositories
2. **Testing**: Add tests for Swift-KMP integration
3. **Documentation**: Document any platform-specific quirks
4. **Performance**: Profile and optimize data transfer between Swift and Kotlin

## Resources

- [Kotlin Multiplatform Documentation](https://kotlinlang.org/docs/multiplatform.html)
- [KMP for iOS](https://kotlinlang.org/docs/multiplatform-mobile-getting-started.html)
- [kotlinx.datetime](https://github.com/Kotlin/kotlinx-datetime)
