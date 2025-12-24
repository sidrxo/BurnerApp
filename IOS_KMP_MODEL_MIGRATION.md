# iOS KMP Model Migration Guide

## Overview

This document explains how iOS models have been migrated to work with the Kotlin Multiplatform (KMP) shared framework.

## Migration Strategy

Instead of replacing Swift models with KMP types directly (which fails due to Codable requirements), we use a **converter-based approach**:

1. **Swift models remain** - They handle Supabase operations (which require Codable conformance)
2. **KMP models are used for business logic** - All filtering, search, sorting, etc. uses shared KMP code
3. **Converters bridge the two** - Seamless conversion between Swift and KMP types

## Architecture

```
┌─────────────────┐
│  Supabase DB    │
└────────┬────────┘
         │ Fetch (Codable required)
         ▼
┌─────────────────┐
│  Swift Models   │  (Event, Ticket, Tag, Venue, Coordinate)
│  (Codable)      │
└────────┬────────┘
         │ .toKMP()
         ▼
┌─────────────────┐
│   KMP Models    │  (Shared.Event, Shared.Ticket, etc.)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ KMP Business    │  (EventFilteringUseCase, SearchUseCase, etc.)
│ Logic           │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   KMP Models    │  (Filtered/processed results)
└────────┬────────┘
         │ .toSwift()
         ▼
┌─────────────────┐
│  Swift Models   │  (Ready for UI)
└─────────────────┘
```

## Key Files

### 1. Model Converters
**File**: `burner/Extensions/KMP/KMPModelConverters.swift`

Provides bidirectional conversion between Swift and KMP models:
- `Event.toKMP()` → `Shared.Event`
- `Shared.Event.toSwift()` → `Event`
- `Date.toKMPInstant()` → `Kotlinx_datetimeInstant`
- `Kotlinx_datetimeInstant.toSwiftDate()` → `Date`

Also includes array converters:
- `[Event].toKMP()` → `[Shared.Event]`
- `[Shared.Event].toSwift()` → `[Event]`

### 2. Repository Adapters
**File**: `burner/Extensions/KMP/KMPRepositoryAdapters.swift`

Swift wrappers around KMP business logic:
- `KMPEventFilteringHelper` - Filter featured, nearby, this week events
- `KMPSearchHelper` - Search and sort events
- `KMPTicketStatusHelper` - Active/past tickets, status tracking
- `KMPDateUtils` - Date formatting utilities
- `KMPPriceUtils` - Price formatting utilities
- `KMPGeoUtils` - Distance calculations

### 3. Updated Repositories
**File**: `burner/Extensions/Repositories/Repository.swift`

Repositories now use KMP business logic:

#### EventRepository
```swift
func fetchFeaturedEvents(limit: Int = 5) async throws -> [Event] {
    // 1. Fetch from Supabase (Swift models)
    let allEvents = try await fetchEventsFromServer(since: Date())

    // 2. Convert to KMP types
    let kmpEvents = allEvents.toKMP()

    // 3. Apply shared KMP filtering logic
    let filteredKMP = filteringHelper.filterFeatured(events: kmpEvents, limit: Int32(limit))

    // 4. Convert back to Swift types
    return filteredKMP.toSwift()
}
```

New methods using KMP logic:
- `fetchFeaturedEvents(limit:)` - Featured events
- `fetchThisWeekEvents(limit:)` - Events this week
- `fetchNearbyEvents(userLatitude:userLongitude:radiusKm:limit:)` - Nearby events
- `fetchEventsByGenre(_:)` - Events by genre
- `searchEvents(query:sortBy:)` - Search events

#### TicketRepository

New methods using KMP logic:
- `getActiveTickets()` - Active tickets
- `getPastTickets()` - Past tickets
- `getTicketsForEvent(eventId:)` - Tickets for event
- `hasConfirmedTicket(eventId:)` - Check ticket status
- `getTotalSpent()` - Total spending
- `sortTicketsByPurchaseDate(ascending:)` - Sort by purchase
- `sortTicketsByEventDate(ascending:)` - Sort by event date

## Usage Examples

### Search Events
```swift
let repository = EventRepository()
let results = try await repository.searchEvents(
    query: "jazz",
    sortBy: .relevance
)
```

### Get Nearby Events
```swift
let repository = EventRepository()
let nearbyEvents = try await repository.fetchNearbyEvents(
    userLatitude: 37.7749,
    userLongitude: -122.4194,
    radiusKm: 25.0,
    limit: 10
)
```

### Get Active Tickets
```swift
let repository = TicketRepository()
// After observeUserTickets populates cachedTickets
let activeTickets = repository.getActiveTickets()
```

### Calculate Distance
```swift
let distance = KMPGeoUtils.calculateDistance(
    from: (lat: 37.7749, lon: -122.4194),  // San Francisco
    to: (lat: 37.3382, lon: -121.8863)     // San Jose
)
print("Distance: \(distance) km")
```

### Format Price
```swift
let formattedPrice = KMPPriceUtils.formatPrice(29.99)
// Output: "$29.99"
```

## Benefits

1. **Shared Business Logic** - Event filtering, search, sorting logic is identical on iOS and Android
2. **Type Safety** - Compile-time type checking ensures correct usage
3. **Seamless Integration** - Existing Swift code continues to work
4. **Gradual Migration** - Can migrate features to KMP incrementally
5. **Supabase Compatibility** - Swift Codable models work with Supabase SDK
6. **Single Source of Truth** - Business rules defined once in KMP, used everywhere

## Next Steps

### Recommended Migration Path

1. ✅ **Phase 1**: Model converters and helpers (COMPLETE)
2. ✅ **Phase 2**: Repository integration (COMPLETE)
3. **Phase 3**: Update ViewModels to use new repository methods
4. **Phase 4**: Remove duplicate filtering/search logic from Swift
5. **Phase 5**: Add more KMP business logic as needed

### ViewModels to Update

Consider updating these ViewModels to use KMP-powered repository methods:

- `EventsViewModel` - Use `fetchFeaturedEvents()`, `searchEvents()`
- `SearchViewModel` - Use `searchEvents()` with KMP sort options
- `TicketsViewModel` - Use `getActiveTickets()`, `getPastTickets()`
- Any view models doing manual event filtering

### Example ViewModel Update

**Before**:
```swift
class EventsViewModel: ObservableObject {
    func loadFeaturedEvents() async {
        let allEvents = try? await repository.fetchEventsFromServer(since: Date())
        self.featuredEvents = allEvents?
            .filter { $0.isFeatured }
            .sorted { $0.featuredPriority ?? 999 < $1.featuredPriority ?? 999 }
            .prefix(5)
            .map { $0 } ?? []
    }
}
```

**After**:
```swift
class EventsViewModel: ObservableObject {
    func loadFeaturedEvents() async {
        self.featuredEvents = try? await repository.fetchFeaturedEvents(limit: 5) ?? []
    }
}
```

## Troubleshooting

### Issue: "Cannot convert value of type 'Event' to expected argument type 'Shared.Event'"
**Solution**: Use `.toKMP()` converter:
```swift
let swiftEvent: Event = ...
let kmpEvent = swiftEvent.toKMP()
```

### Issue: "Value of type 'Kotlinx_datetimeInstant' has no member 'timeIntervalSince1970'"
**Solution**: Use `.toSwiftDate()` converter:
```swift
let kmpInstant: Kotlinx_datetimeInstant = ...
let swiftDate = kmpInstant.toSwiftDate()
```

### Issue: Build errors about missing Shared module
**Solution**: Ensure the shared.framework is built and linked:
```bash
cd shared
./gradlew :shared:assembleSharedReleaseXCFramework
```

Then in Xcode:
1. Add `shared/build/XCFrameworks/release/Shared.xcframework` to project
2. Set to "Embed & Sign" in target settings

## Performance Considerations

- **Conversion overhead**: Minimal - converters create new instances but are lightweight
- **Memory**: Swift and KMP models exist separately during conversion
- **Optimization**: For frequently used data, cache converted results if needed

## Testing

When testing code that uses KMP:

1. **Unit tests**: Test converters with edge cases (nil values, extreme dates)
2. **Integration tests**: Verify repository methods return correct data
3. **Performance tests**: Measure conversion overhead if needed

Example test:
```swift
func testEventConversion() {
    let swiftEvent = Event(/* ... */)
    let kmpEvent = swiftEvent.toKMP()
    let roundTrip = kmpEvent.toSwift()

    XCTAssertEqual(swiftEvent.id, roundTrip.id)
    XCTAssertEqual(swiftEvent.name, roundTrip.name)
    // etc.
}
```

## Summary

This migration strategy provides the best of both worlds:
- Swift models remain for Supabase integration (Codable required)
- KMP business logic provides shared, tested functionality
- Converters make the integration seamless and type-safe

The result is a codebase where business logic is shared across platforms while maintaining full compatibility with platform-specific requirements.
