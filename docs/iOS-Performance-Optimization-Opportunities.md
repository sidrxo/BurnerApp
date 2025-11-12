# iOS App Performance & Optimization Opportunities

**Document Version:** 1.0
**Date:** 2025-11-12
**Scope:** iOS App Only

---

## Executive Summary

This document identifies opportunities for improving the Burner iOS app across six critical dimensions:
1. **Firestore Efficiency** - Reducing read/write operations and costs
2. **Performance** - Improving app responsiveness and load times
3. **User Experience** - Enhancing usability and polish
4. **App Size** - Reducing download and installation footprint
5. **Architecture** - Improving code maintainability and scalability
6. **Code Quality** - Removing redundancy and deprecated patterns

---

## Table of Contents

1. [Firestore Read/Write Optimization](#1-firestore-readwrite-optimization)
2. [Performance Improvements](#2-performance-improvements)
3. [User Experience Enhancements](#3-user-experience-enhancements)
4. [App Size Reduction](#4-app-size-reduction)
5. [Architecture Improvements](#5-architecture-improvements)
6. [Code Quality & Best Practices](#6-code-quality--best-practices)
7. [Implementation Priority Matrix](#7-implementation-priority-matrix)

---

## 1. Firestore Read/Write Optimization

### 🔴 Critical Issues

#### 1.1 Inefficient Bookmark Event Fetching
**File:** `burner/Extensions/Managers/BookmarkManager.swift:60-74`

**Problem:**
```swift
for eventId in eventIds {
    if let event = try? await eventRepository.fetchEvent(by: eventId) {
        events.append(event)
    }
}
```
- Fetches bookmarked events **one at a time** in a loop
- For 10 bookmarks = **10 separate Firestore reads**
- No batching or parallelization

**Impact:**
- High Firestore read costs
- Slow bookmark loading (sequential blocking calls)
- Poor UX when users have many bookmarks

**Solution:**
- Use `whereIn` query to fetch multiple events in a single read (max 10 per query)
- Batch queries for >10 bookmarks
- Use `Task.detached` for parallel fetching

**Estimated Savings:** 90% reduction in Firestore reads for bookmarks

---

#### 1.2 Redundant Search Repository in SearchView
**File:** `burner/SearchView.swift:22-23`

**Problem:**
```swift
init() {
    let repository = OptimizedEventRepository()
    _viewModel = StateObject(wrappedValue: SearchViewModel(eventRepository: repository))
}
```
- Creates a **separate** `OptimizedEventRepository` instance
- **Bypasses** the real-time listener in `AppState.eventRepository`
- Fetches events again from Firestore instead of using cached data
- `SearchView.swift:399` fetches **100 events** for nearby sorting

**Impact:**
- Duplicate Firestore reads on every search
- Wasted bandwidth and read costs
- Inconsistent data (search results may differ from main events list)

**Solution:**
- Pass `AppState.eventViewModel.events` to `SearchViewModel`
- Filter/search locally on already-loaded events
- Only fetch from Firestore for advanced queries

**Estimated Savings:** 80-100% reduction in search-related Firestore reads

---

#### 1.3 No Firestore Query Indexing Strategy
**File:** Multiple repository files

**Problem:**
- Complex queries without documented indexes
- `Repository.swift:76-77` - Composite query: `whereField + order(by: purchaseDate)`
- `Repository.swift:112-114` - Triple filter query for ticket status

**Impact:**
- Slower queries (full collection scans)
- Higher server costs
- Potential runtime errors if indexes missing

**Solution:**
- Create Firestore composite indexes for:
  - `tickets`: `(userId, purchaseDate)`
  - `tickets`: `(userId, eventId, status)`
  - `events`: `(startTime, status)`
- Document required indexes in `/docs/firestore-indexes.md`

---

#### 1.4 Nearby Events Fetches All Events
**File:** `burner/SearchView.swift:399`

**Problem:**
```swift
let allEvents = try await eventRepository.fetchUpcomingEvents(sortBy: "startTime", limit: 100)
```
- Fetches **100 events** to sort by distance client-side
- No geospatial filtering

**Impact:**
- Unnecessary Firestore reads
- Processes many irrelevant events (events 1000+ miles away)

**Solution:**
- Use GeoFirestore library for radius-based queries
- Fetch only events within 50km radius
- Reduce limit to 20-30 events

**Estimated Savings:** 70% reduction in nearby search reads

---

#### 1.5 Real-time Listener on All Events (No Filtering)
**File:** `burner/Extensions/Repositories/Repository.swift:24-46`

**Problem:**
```swift
func observeEvents(completion: @escaping (Result<[Event], Error>) -> Void) {
    eventsListener = db.collection("events")
        .order(by: "startTime", descending: false)
        .addSnapshotListener { ... }
}
```
- Listens to **ALL events** in database
- No date filtering (includes past events)
- Client-side filtering in `ExploreView.swift` and `SearchView.swift`

**Impact:**
- Downloads and processes hundreds of past/irrelevant events
- Wastes bandwidth on every real-time update
- Higher read costs as database grows

**Solution:**
- Add server-side filter: `.whereField("startTime", isGreaterThan: Date())`
- Limit to next 30-60 days of events: `.whereField("startTime", isLessThan: Date().addingTimeInterval(60*24*60*60))`
- Reduce listener scope to relevant data only

**Estimated Savings:** 60-80% reduction in event listener reads

---

### 🟡 Medium Priority

#### 1.6 Ticket Status Check Fetches All User Tickets
**File:** `burner/Extensions/Repositories/Repository.swift:111-126`

**Problem:**
```swift
func fetchUserTicketStatus(userId: String, eventIds: [String]) async throws -> [String: Bool] {
    let snapshot = try await db.collection("tickets")
        .whereField("userId", isEqualTo: userId)
        .whereField("status", isEqualTo: "confirmed")
        .getDocuments()
    // ...
}
```
- Fetches **all confirmed tickets** for user
- Filters event IDs client-side
- Called every time events list updates

**Solution:**
- Use batch `whereIn` queries for specific event IDs (max 10 at a time)
- Cache results in `EventViewModel` with TTL (5 min)
- Only re-fetch when user ID changes

**Estimated Savings:** 50% reduction in ticket status reads

---

#### 1.7 No Offline Persistence Enabled
**File:** `burner/App/BurnerApp.swift`

**Problem:**
- Firestore offline persistence is **not enabled**
- Every app cold start fetches all data from network
- No caching between sessions

**Solution:**
```swift
let settings = Firestore.firestore().settings
settings.isPersistenceEnabled = true
Firestore.firestore().settings = settings
```

**Benefits:**
- Instant app startup with cached data
- Reduced Firestore reads
- Better offline experience

---

## 2. Performance Improvements

### 🔴 Critical Issues

#### 2.1 Synchronous Image Loading (Kingfisher Not Optimized)
**Files:** `ExploreView.swift`, `SearchView.swift`, EventRow components

**Problem:**
- Heavy use of Kingfisher for images but no custom configuration
- Default cache settings may be suboptimal
- No prefetching or preloading strategy

**Solution:**
- Configure Kingfisher with:
  - Memory cache limit: 100MB
  - Disk cache limit: 300MB
  - Downsampling for thumbnails
  - Background decoding
- Implement prefetch for visible rows in `LazyVStack`

**Example:**
```swift
KFImage(URL(string: event.imageUrl))
    .placeholder { ProgressView() }
    .cacheMemoryOnly()
    .downsampling(size: CGSize(width: 400, height: 300))
    .backgroundDecode()
```

---

#### 2.2 Inefficient Nearby Event Distance Calculation
**File:** `burner/ExploreView.swift:61-98`

**Problem:**
```swift
let eventsWithDistance = eventsWithCoordinates.compactMap { event -> (Event, CLLocationDistance)? in
    guard let coordinates = event.coordinates else { return nil }
    let eventLocation = CLLocation(latitude: ..., longitude: ...)
    let distance = userLocation.distance(from: eventLocation)
    // ...
}
```
- Calculates distance for **every event** on every view render
- No memoization or caching

**Solution:**
- Cache distance calculations in dictionary: `[eventId: distance]`
- Only recalculate when user location changes significantly (>1km)
- Perform calculation in background Task

---

#### 2.3 SearchViewModel In-Memory Cache Never Expires
**File:** `burner/SearchView.swift:244`

**Problem:**
```swift
private var searchCache: [String: [Event]] = [:]
```
- No TTL (time-to-live) for cached search results
- Stale data can be shown indefinitely
- Memory leak potential with unlimited cache growth

**Solution:**
- Add cache expiration (5 min TTL)
- Implement LRU (Least Recently Used) eviction
- Clear cache when events update via real-time listener

---

#### 2.4 Sequential Bookmark Event Fetching (Also UX Issue)
**File:** `burner/Extensions/Managers/BookmarkManager.swift:60-74`

**Problem:**
- Already covered in Firestore section
- Also causes **UI freezes** during fetch

**Solution:**
- Use parallel fetching with `TaskGroup`
- Show loading spinner during fetch
- Load bookmarks incrementally (first 5, then rest)

---

### 🟡 Medium Priority

#### 2.5 ExploreView Computes All Sections on Every Render
**File:** `burner/ExploreView.swift`

**Problem:**
```swift
var featuredEvents: [Event] { ... }
var thisWeekEvents: [Event] { ... }
var popularEvents: [Event] { ... }
var nearbyEvents: [(event: Event, distance: CLLocationDistance)] { ... }
```
- All computed properties recalculate on **every view update**
- Expensive filtering/sorting runs repeatedly
- No memoization

**Solution:**
- Use `@State private var cachedFeaturedEvents: [Event] = []`
- Compute once in `.task { }` modifier
- Only recompute when `eventViewModel.events` changes (use `.onChange`)

---

#### 2.6 No Image Dimension Optimization
**Files:** All views using event images

**Problem:**
- Event images loaded at full resolution
- No responsive sizing based on device/screen size
- Wastes bandwidth and memory on smaller devices

**Solution:**
- Serve multiple image sizes from backend (small/medium/large)
- Use `@1x`, `@2x`, `@3x` variants based on device scale
- Implement lazy loading for off-screen images

---

## 3. User Experience Enhancements

### 🔴 Critical Issues

#### 3.1 No Loading State for Bookmark Toggle
**File:** `burner/Extensions/Managers/BookmarkManager.swift:95-136`

**Problem:**
- Bookmark toggle is optimistic but no loading indicator
- User can rapidly tap causing race conditions
- No error feedback to user (silent failure on line 133)

**Solution:**
- Add `@Published var isTogglingBookmark: [String: Bool] = [:]` state
- Disable bookmark button during toggle
- Show error alert on failure with retry option

---

#### 3.2 Search Loading State Missing
**File:** `burner/SearchView.swift:200-230`

**Problem:**
- Shows loading only if `viewModel.events.isEmpty`
- When searching with existing results, no loading indicator
- User doesn't know if search is processing

**Solution:**
- Add shimmer loading overlay on search bar when `isLoading`
- Show "Searching..." text in empty state
- Debounce search text changes (already implemented at 300ms)

---

#### 3.3 Poor Error Handling in Payment Flow
**File:** `burner/Extensions/Services/StripePaymentService.swift`

**Problem:**
- Errors shown via `errorMessage` string only
- No structured error types
- Generic error messages: "Payment failed. Please try again"
- No retry mechanism

**Solution:**
- Create `PaymentError` enum with user-friendly messages
- Implement automatic retry for network failures
- Show actionable error messages ("Card declined - Try another card")
- Add "Contact Support" button for persistent errors

---

#### 3.4 No Haptic Feedback for Key Actions
**Files:** Multiple views

**Problem:**
- Bookmark toggle has haptic (good!) but others don't
- No feedback for:
  - Ticket purchase success
  - Event navigation
  - Search filter changes

**Solution:**
- Add haptic feedback for:
  - Payment success: `.notificationFeedback(.success)`
  - Filter changes: `.impactFeedback(.light)`
  - Ticket QR code display: `.impactFeedback(.medium)`

---

#### 3.5 Empty States Need Improvement
**Files:** `SearchView.swift:542-573`, ticket/bookmark empty states

**Problem:**
- Generic empty state messages
- No actionable CTAs (calls-to-action)
- Static icon only

**Solution:**
- Add contextual CTAs:
  - **No bookmarks:** "Tap ♡ on any event to save it here"
  - **No tickets:** "Browse Events" button
  - **No search results:** "Try different keywords" + suggestion chips
- Add illustration/animation for empty states

---

### 🟡 Medium Priority

#### 3.6 No Pull-to-Refresh
**Files:** `ExploreView.swift`, `TicketsView.swift`, `SearchView.swift`

**Problem:**
- Real-time listeners auto-update but no manual refresh option
- Users expect pull-to-refresh on iOS
- No way to force reload if listener fails

**Solution:**
- Add `.refreshable` modifier to ScrollViews
- Trigger `eventViewModel.fetchEvents()` on pull
- Show refresh indicator

---

#### 3.7 Location Permission UX
**File:** `burner/SearchView.swift:269-271`

**Problem:**
- Requests location permission inline when tapping "NEARBY"
- No explanation before requesting permission
- User may deny without understanding why it's needed

**Solution:**
- Show pre-permission alert explaining benefit:
  - "Find events near you"
  - "We'll show events within 30 miles"
- Add "Not now" option to skip
- Store permission denial to avoid re-asking

---

#### 3.8 Ticket QR Code Should Be Brighter
**File:** Ticket detail views (inferred from architecture)

**Problem:**
- Dark mode UI may dim QR code
- Scanners need high contrast

**Solution:**
- Force QR code area to white background
- Increase screen brightness when QR code shown
- Add "Tap to enlarge" feature

---

#### 3.9 No Skeleton Loading for Images
**Files:** All event card components

**Problem:**
- Blank space while images load
- Jarring content shift when image appears

**Solution:**
- Use Kingfisher's `.placeholder` with shimmer effect
- Reserve image space with fixed aspect ratio
- Fade-in animation on load

---

## 4. App Size Reduction

### 🔴 Critical Issues

#### 4.1 Large Firebase SDK Footprint
**Problem:**
- Using **5 Firebase modules**: Core, Auth, Firestore, Functions
- Firestore alone adds ~10MB to app size

**Solution:**
- Remove unused Firebase modules if any
- Enable **bitcode** (reduces size by ~30%)
- Use **Firebase Analytics** sparingly (or remove if not needed)
- Enable **App Thinning** in Xcode build settings

**Estimated Savings:** 3-5MB

---

#### 4.2 Stripe SDK Size
**Problem:**
- Using 3 Stripe modules: `Stripe`, `StripePaymentSheet`, `StripeApplePay`
- Adds ~8-12MB to app

**Solution:**
- Verify all three modules are needed
- Consider using `StripePaymentSheet` only (includes ApplePay)
- Enable **dynamic linking** if not already enabled

**Estimated Savings:** 2-4MB

---

#### 4.3 No Image Asset Optimization
**Files:** `burner/Assets.xcassets/`

**Problem:**
- App may contain unoptimized images
- No vector assets (SF Symbols usage is good)
- Potential duplicate/unused assets

**Solution:**
- Run `imageoptim` or `pngcrush` on all image assets
- Convert appropriate images to vector PDFs
- Remove unused assets via Xcode "Find Unused Assets"
- Use HEIC format for photos (50% smaller than PNG)

**Estimated Savings:** 1-3MB

---

### 🟡 Medium Priority

#### 4.4 Kingfisher Image Library
**Problem:**
- Kingfisher adds ~2MB
- Provides caching/loading features

**Solution:**
- **Keep Kingfisher** (benefits outweigh size cost)
- Consider lighter alternative like `SDWebImage` (saves ~500KB)
- Or implement custom URLSession-based image loader

---

#### 4.5 Dead Code Elimination
**Problem:**
- Debug simulation code in production:
  - `EventViewModel.simulateEmptyData()`
  - `TicketsViewModel.simulateEmptyData()`
- Unused preview code

**Solution:**
- Wrap debug code in `#if DEBUG` blocks
- Remove SwiftUI previews from release builds
- Run **SwiftLint** with dead code detection

**Estimated Savings:** 0.5-1MB

---

## 5. Architecture Improvements

### 🔴 Critical Issues

#### 5.1 Hardcoded Stripe API Key in Source Code
**File:** `burner/Extensions/Services/StripePaymentService.swift:48-49`

**Problem:**
```swift
// TODO: Move this to an env/remote-config before production.
StripeAPI.defaultPublishableKey = "pk_test_51SKOqrFxXnVDuRLXw30ABLXPF9QyorMesOCHN9sMbRAIokEIL8gptsxxX4APRJSO0b8SRGvyAUBNzBZqCCgOSvVI00fxiHOZNe"
```

**Impact:**
- **SECURITY RISK:** Test key exposed in Git history
- Cannot switch keys without app update
- No environment separation (dev/staging/prod)

**Solution:**
- Move to **Firebase Remote Config**:
  ```swift
  let remoteConfig = RemoteConfig.remoteConfig()
  StripeAPI.defaultPublishableKey = remoteConfig["stripe_key"].stringValue
  ```
- Or use **Config.plist** (excluded from Git):
  ```swift
  guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
        let config = NSDictionary(contentsOfFile: path),
        let key = config["StripePublishableKey"] as? String else { ... }
  ```

---

#### 5.2 Duplicate Location Manager Instances
**Files:**
- `burner/SearchView.swift:249` - `LocationManager`
- `burner/App/AppState.swift:16` - `UserLocationManager`

**Problem:**
- Two separate CoreLocation manager implementations
- `SearchView` creates its own instead of using shared one
- Redundant code and potential conflicts

**Solution:**
- Remove `LocationManager` from `SearchView.swift`
- Use `@EnvironmentObject var userLocationManager: UserLocationManager`
- Consolidate all location logic in one manager

---

#### 5.3 Repository Inconsistency
**Files:**
- `burner/Extensions/Repositories/Repository.swift` - Real-time repositories
- `burner/SearchView.swift:444-540` - `OptimizedEventRepository` (no real-time)

**Problem:**
- Two different repository patterns for same data (Events)
- Inconsistent data source
- Violates Single Responsibility Principle

**Solution:**
- Merge `OptimizedEventRepository` functionality into `EventRepository`
- Add search/filter methods to main repository
- Remove duplicate code

---

#### 5.4 No Dependency Injection Container
**File:** `burner/App/AppState.swift:55-96`

**Problem:**
- AppState manually creates all dependencies
- Hard to test (tightly coupled)
- Difficult to mock services for unit tests

**Solution:**
- Implement simple DI container or use library like **Swinject**
- Make repositories/services injectable protocols
- Enable unit testing of ViewModels

**Example:**
```swift
protocol EventRepositoryProtocol {
    func observeEvents(completion: @escaping (Result<[Event], Error>) -> Void)
}

class EventViewModel {
    init(eventRepository: EventRepositoryProtocol) { ... }
}
```

---

### 🟡 Medium Priority

#### 5.5 Navigation Coordinator Could Use Enum-Based Routing
**File:** `burner/Extensions/Navigation/NavigationCoordinator.swift`

**Current:** Uses `NavigationDestination` enum (good!)

**Improvement:**
- Add deep link handling to coordinator
- Centralize all navigation logic
- Add analytics tracking to navigation events

---

#### 5.6 No Separation of Business Logic from ViewModels
**Problem:**
- ViewModels contain both UI state AND business logic
- Hard to reuse logic across features
- Testing requires UI framework

**Solution:**
- Extract business logic to **Use Cases** or **Interactors**
- ViewModels become thin wrappers
- Example: `PurchaseTicketUseCase`, `BookmarkEventUseCase`

---

## 6. Code Quality & Best Practices

### 🔴 Critical Issues

#### 6.1 Disabled DeviceActivityMonitor Extension
**File:** Git commit: `"disabled deviceactivitymonitor"`

**Problem:**
- Extension exists but is disabled
- Dead code in codebase
- Unclear if feature is abandoned or temporarily disabled

**Solution:**
- If permanently disabled: **Remove extension completely**
- If temporarily disabled: Add documentation explaining why and when to re-enable
- Clean up related code in `BurnerModeManager.swift`

---

#### 6.2 Silent Error Swallowing
**Files:** Multiple locations

**Examples:**
- `BookmarkManager.swift:133` - Catches error but doesn't log or report
- `EventViewModel.swift:118` - Silently fails ticket status check

**Problem:**
- Errors go unreported to developers
- Debugging production issues is impossible
- Users experience silent failures

**Solution:**
- Implement centralized error logging (Firebase Crashlytics)
- Add analytics for error tracking
- Log all errors to console in debug builds:
  ```swift
  #if DEBUG
  print("❌ Error: \(error)")
  #endif
  ```

---

#### 6.3 Force Unwrapping and Unsafe Optionals
**Files:** Multiple (need full code audit)

**Problem:**
- Use of `!` force unwrapping (crashes if nil)
- `try?` hiding errors without handling

**Solution:**
- Run SwiftLint with strict optional rules
- Replace `!` with `guard let` or `if let`
- Replace `try?` with `try` + proper error handling

---

#### 6.4 No Error Boundary Pattern
**Problem:**
- Errors propagate up to root view
- App can crash or show white screen

**Solution:**
- Implement error boundary views
- Catch errors at feature boundaries
- Show fallback UI with "Retry" option

---

### 🟡 Medium Priority

#### 6.5 Inconsistent Code Style
**Problem:**
- Mixed use of `async/await` and completion handlers
- Some files use `self.` prefix, others don't

**Solution:**
- Adopt **SwiftLint** with project-specific rules
- Standardize on `async/await` for all new code
- Add `.swiftlint.yml` configuration

---

#### 6.6 No Unit Tests
**Problem:**
- No test target visible in project structure
- ViewModels and business logic untested

**Solution:**
- Add unit test target
- Write tests for:
  - Repositories (mock Firestore)
  - ViewModels (test state changes)
  - Business logic (bookmark, payment flow)
- Aim for 60%+ code coverage

---

#### 6.7 Magic Numbers Throughout Code
**Examples:**
- `ExploreView.swift:18` - `maxNearbyDistance = 50_000`
- `SearchView.swift:252` - `initialLoadLimit = 6`
- `BurnerModeManager.swift:27` - `minimumCategoriesRequired = 8`

**Solution:**
- Move to configuration file or constants struct:
  ```swift
  struct AppConstants {
      static let maxNearbyDistanceMeters: CLLocationDistance = 50_000
      static let searchInitialLoadLimit = 6
      static let burnerModeMinCategories = 8
  }
  ```

---

#### 6.8 No Documentation for Complex Logic
**Files:**
- `BurnerModeManager.swift` - Screen Time API usage
- `StripePaymentService.swift` - Payment flow

**Solution:**
- Add doc comments for public methods:
  ```swift
  /// Enables Burner Mode by applying Screen Time restrictions.
  /// - Requires: User authorization and minimum 8 categories selected
  /// - Throws: `BurnerModeError` if setup invalid or unauthorized
  func enable() async throws { ... }
  ```

---

## 7. Implementation Priority Matrix

### Phase 1: Quick Wins (Low Effort, High Impact)
1. ✅ Fix hardcoded Stripe key → Firebase Remote Config
2. ✅ Enable Firestore offline persistence
3. ✅ Add pull-to-refresh to main views
4. ✅ Implement haptic feedback for key actions
5. ✅ Filter events listener to upcoming only
6. ✅ Add error logging (Crashlytics)
7. ✅ Remove/document disabled DeviceActivityMonitor

**Estimated Time:** 1-2 days
**Impact:** Security fix, 40% Firestore read reduction, better UX

---

### Phase 2: Performance Optimizations (Medium Effort, High Impact)
1. ✅ Batch bookmark event fetching
2. ✅ Remove duplicate `OptimizedEventRepository`
3. ✅ Cache ExploreView computed properties
4. ✅ Add search cache expiration
5. ✅ Implement Kingfisher optimizations
6. ✅ Parallelize image loading
7. ✅ Add Firestore composite indexes

**Estimated Time:** 3-5 days
**Impact:** 60% faster bookmark loading, 80% fewer Firestore reads, smoother UI

---

### Phase 3: Architecture Refactoring (High Effort, High Long-term Value)
1. ✅ Consolidate location managers
2. ✅ Merge repository implementations
3. ✅ Implement dependency injection
4. ✅ Separate business logic from ViewModels
5. ✅ Add unit test coverage
6. ✅ Implement error boundaries

**Estimated Time:** 1-2 weeks
**Impact:** Better testability, maintainability, code reuse

---

### Phase 4: Polish & Optimization (Variable Effort)
1. ✅ Improve empty states with CTAs
2. ✅ Add skeleton loading
3. ✅ Optimize app bundle size
4. ✅ Add SwiftLint rules
5. ✅ Image asset optimization
6. ✅ Document complex logic
7. ✅ Create configuration management system

**Estimated Time:** 1 week
**Impact:** Better UX, smaller app, easier onboarding for new devs

---

## Appendix A: Firestore Read Cost Estimation

### Current Monthly Reads (Estimated)
Assuming 1,000 active users:

| Operation | Reads per User | Total Daily | Monthly Cost |
|-----------|---------------|-------------|--------------|
| Event listener (all events) | 200 | 200,000 | $0.12 |
| Bookmark fetches (10 bookmarks) | 10 | 10,000 | $0.006 |
| Search queries (3/day) | 100 | 300,000 | $0.18 |
| Ticket status checks | 50 | 50,000 | $0.03 |
| Nearby event fetches | 100 | 100,000 | $0.06 |
| **TOTAL** | | **760,000** | **~$0.40/day** |

**Monthly:** ~$12/month for 1K users

---

### After Optimizations
| Operation | Reads per User | Total Daily | Monthly Cost |
|-----------|---------------|-------------|--------------|
| Event listener (filtered) | 60 | 60,000 | $0.036 |
| Bookmark fetches (batched) | 1 | 1,000 | $0.0006 |
| Search queries (cached) | 20 | 20,000 | $0.012 |
| Ticket status checks (cached) | 10 | 10,000 | $0.006 |
| Nearby event fetches (GeoFirestore) | 20 | 20,000 | $0.012 |
| **TOTAL** | | **111,000** | **~$0.067/day** |

**Monthly:** ~$2/month for 1K users

**Savings:** **83% reduction** in Firestore costs

---

## Appendix B: Recommended Tools & Libraries

### Performance Monitoring
- **Firebase Performance Monitoring** - Track app startup, screen load times
- **MetricKit** - Apple's native performance metrics
- **Instruments** - Profile memory, CPU, network usage

### Code Quality
- **SwiftLint** - Style and best practices enforcement
- **SwiftFormat** - Automatic code formatting
- **Periphery** - Dead code detection

### Testing
- **Quick/Nimble** - BDD-style testing framework
- **OHHTTPStubs** - Mock network requests for testing

### Optimization
- **ImageOptim** - Image compression
- **Firebase Remote Config** - Feature flags and config management
- **GeoFirestore** - Geospatial queries for Firestore

---

## Conclusion

The Burner iOS app has a solid architectural foundation with good separation of concerns and modern SwiftUI patterns. However, there are significant opportunities to improve:

**Top 3 Priorities:**
1. **Fix Firestore inefficiencies** (83% cost reduction potential)
2. **Remove hardcoded secrets** (security risk)
3. **Improve loading states and error handling** (better UX)

By implementing the recommendations in Phases 1-2, the app will see:
- ✅ **60-80% reduction in Firestore costs**
- ✅ **2-3x faster bookmark and search operations**
- ✅ **Better offline experience**
- ✅ **Improved security and configuration management**

The refactoring work in Phases 3-4 will position the codebase for:
- ✅ **Easier feature development**
- ✅ **Better testability and quality**
- ✅ **Reduced onboarding time for new developers**

---

**Document Maintainer:** Claude Code
**Last Updated:** 2025-11-12
**Next Review:** After Phase 1 implementation
