# Burner App - Kotlin Multiplatform Shared Module

This module contains shared business logic, data models, and repositories that are used by both the iOS and Android applications.

## 📦 What's Shared

### Data Models (`models/`)
- **Event** - Event information with computed properties (isPast, isAvailable, ticketsRemaining, etc.)
- **Ticket** - Ticket model with status tracking
- **User** - User profile and preferences
- **Venue** - Venue information
- **Bookmark** - Bookmarked events
- **Tag** - Event genres/tags
- **Coordinate** - Geographic coordinates

### Repositories (`repositories/`)
- **EventRepository** - Fetch events, search, filter by genre, nearby events
- **TicketRepository** - Fetch user tickets, check ticket ownership
- **BookmarkRepository** - Manage event bookmarks
- **UserRepository** - User profile management
- **TagRepository** - Fetch genres/tags

### Business Logic (`domain/`)
- **EventFilteringUseCase** - Filter events (featured, this week, nearby, by genre)
- **SearchUseCase** - Search and sort events
- **TicketStatusTracker** - Track ticket status, count, and spending

### Services (`services/`)
- **AuthService** - Authentication (sign in, sign up, sign out, password reset)

### Utilities (`utils/`)
- **GeoUtils** - Haversine distance calculation
- **DateUtils** - Date formatting and relative time strings
- **PriceUtils** - Price formatting

## 🎯 Key Features

### Computed Properties
All models include computed properties that work identically on both platforms:

```kotlin
// Event
event.isPast          // Checks if event is past (6 AM day after event)
event.isAvailable     // Has tickets remaining
event.ticketsRemaining // Tickets left
event.distanceFrom(lat, lon)  // Distance from user

// Ticket
ticket.isUpcoming     // Is future event with confirmed/used status
ticket.isActive       // Status is confirmed or used
ticket.isPast         // Past event or cancelled/refunded
```

### Date Handling
Uses `kotlinx.datetime` for cross-platform date operations:

```kotlin
val instant = event.startInstant  // Instant?
val formatted = DateUtils.formatDateTime(instant)
val relative = DateUtils.getRelativeTimeString(instant)
```

### Distance Calculations
Haversine formula for geographic distance:

```kotlin
val distance = haversineDistance(lat1, lon1, lat2, lon2)  // Returns km
val nearby = events.filter {
    it.distanceFrom(userLat, userLon)?.let { d -> d <= 50.0 } ?: false
}
```

## 🔧 Usage

### iOS Integration

The shared module is compiled to an iOS framework. Import it in your Swift files:

```swift
import Shared

// Use shared models
let event = Event(name: "Rave", venue: "Printworks", ...)
if event.isPast { /* ... */ }

// Use repositories
let eventRepo = EventRepository(supabaseClient: client)
let events = try await eventRepo.fetchEvents()
```

### Android Integration

Add the shared module as a dependency:

```kotlin
dependencies {
    implementation(project(":shared"))
}
```

Use in your Android code:

```kotlin
import com.burner.shared.models.Event
import com.burner.shared.repositories.EventRepository

// Use shared models
val event = Event(name = "Rave", venue = "Printworks", ...)
if (event.isPast) { /* ... */ }

// Use repositories
val eventRepo = EventRepository(supabaseClient)
val events = eventRepo.fetchEvents()
```

## 🏗️ Architecture

### Expect/Actual Pattern

Platform-specific implementations use the `expect`/`actual` pattern:

```kotlin
// Common code
expect class SupabaseClient {
    fun from(table: String): QueryBuilder
}

// Android implementation (androidMain)
actual class SupabaseClient { /* ... */ }

// iOS implementation (iosMain)
actual class SupabaseClient { /* ... */ }
```

This allows platform-specific implementations while keeping the API consistent.

## 📊 Benefits

### For Development
- **Write Once, Run Everywhere** - Business logic written once, works on both platforms
- **Type Safety** - Compile-time checks prevent errors
- **Consistent Behavior** - Identical logic on iOS and Android
- **Easier Testing** - Write tests once for shared code

### For Maintenance
- **Single Source of Truth** - Models and logic defined in one place
- **Faster Bug Fixes** - Fix once, deploys to both platforms
- **Reduced Duplication** - ~40% less code to maintain

### For Features
- **Faster Development** - New features implemented once
- **Guaranteed Consistency** - Logic can't drift between platforms
- **Shared Tests** - Business logic tests run on both platforms

## 🚀 Migration Strategy

1. ✅ **Phase 1: Data Models** - All models now shared
2. ✅ **Phase 2: Repositories** - All repositories now shared
3. ✅ **Phase 3: Business Logic** - Use cases and services shared
4. 🔄 **Phase 4: Integration** - Update iOS and Android to use shared code
5. 📝 **Phase 5: Testing** - Add comprehensive tests for shared code

## 📝 Notes

### Based on iOS Implementation
The shared code uses the iOS app's logic as the primary reference, with adjustments for:
- Cross-platform compatibility
- Kotlin idioms and best practices
- Platform-agnostic date/time handling
- Consistent serialization

### Platform-Specific Code
Some functionality remains platform-specific:
- UI components (SwiftUI vs Jetpack Compose)
- Platform features (NFC, Live Activities, etc.)
- Navigation
- Local storage (UserDefaults vs DataStore)

## 🔗 Dependencies

- `kotlinx-serialization` - JSON serialization
- `kotlinx-datetime` - Cross-platform date/time
- `kotlinx-coroutines` - Async operations
- `supabase-kt` - Supabase client for Kotlin Multiplatform

## 📚 Learn More

- [Kotlin Multiplatform Documentation](https://kotlinlang.org/docs/multiplatform.html)
- [KMP for Mobile](https://kotlinlang.org/docs/multiplatform-mobile-getting-started.html)
- [CODE_SHARING_ANALYSIS.md](../CODE_SHARING_ANALYSIS.md) - Detailed analysis and migration plan
