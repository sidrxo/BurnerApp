# BurnerApp - Code Audit & Architecture Improvements

**Date:** November 4, 2025
**Scope:** Button functionality, redundant code, and architectural improvements

---

## 🔴 CRITICAL ISSUES FOUND & FIXED

### 1. **Non-Functional Buttons - FIXED ✅**

#### Bookmark Buttons (When Not Signed In)
- **Location:**
  - `burner/Components/CustomRows.swift:265-276`
  - `burner/Components/FeaturedHeroCard.swift:80-90`
  - `burner/Tickets/EventDetailView.swift:237-247`
- **Issue:** Bookmark buttons did nothing when user was not signed in
- **Fix Applied:** Added authentication check - now shows sign-in sheet when user tries to bookmark without being authenticated
- **Status:** ✅ FIXED

#### Sign In Button on Event Detail Alert
- **Location:** `burner/Tickets/EventDetailView.swift:314`
- **Status:** ✅ Already working correctly - properly triggers `appState.isSignInSheetPresented = true`

#### Delete Account Button
- **Location:** `burner/Settings/AccountDetailsView.swift:156-170`
- **Current Status:** Partially functional
- **Issues:**
  - Firebase requires recent authentication for sensitive operations like account deletion
  - Current implementation doesn't handle `FIRAuthErrorCodeRequiresRecentLogin` error
  - User may see cryptic error when trying to delete account after being signed in for a while
- **Recommended Fix:**
```swift
private func deleteAccount() {
    guard let user = Auth.auth().currentUser else { return }

    appState.handleManualSignOut()

    user.delete { error in
        if let error = error as NSError? {
            if error.code == AuthErrorCode.requiresRecentLogin.rawValue {
                // Show alert asking user to re-authenticate
                self.showReauthenticationAlert = true
            } else {
                // Handle other errors
                self.showErrorAlert(message: error.localizedDescription)
            }
        } else {
            NotificationCenter.default.post(name: NSNotification.Name("UserSignedOut"), object: nil)
            presentationMode.wrappedValue.dismiss()
        }
    }
}
```

#### Passwordless Sign-Up URL
- **Location:** `burner/Settings/Passwordless/PasswordlessAuthView.swift:260`
- **Issue:** Deep link handling wasn't integrated into main app
- **Fix Applied:**
  - Added `PasswordlessAuthHandler` to `AppState`
  - Integrated handler into `BurnerApp.swift`'s `onOpenURL` flow
- **Status:** ✅ FIXED

---

## 🔄 REDUNDANT CODE PATTERNS

### 1. **Duplicate Button Styling**
**Locations:** Throughout the app (20+ files)

**Current Pattern (Redundant):**
```swift
Button("Text") { }
    .appBody()
    .foregroundColor(.white)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .background(Color.white.opacity(0.15))
    .clipShape(RoundedRectangle(cornerRadius: 12))
```

**Problem:**
- Button styling repeated in 15+ different view files
- Inconsistent corner radii (8px, 10px, 12px, 14px, 23px)
- Inconsistent padding (12px, 14px, 16px)
- Inconsistent opacity values (0.05, 0.1, 0.15, 0.2, 0.3)

**Recommendation:** Create reusable button styles

```swift
// burner/Components/ButtonStyles.swift
struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appFont(size: 17))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isEnabled ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appFont(size: 17))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appFont(size: 17))
            .foregroundColor(.red)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}
```

**Usage:**
```swift
Button("Continue") { }
    .buttonStyle(PrimaryButtonStyle(isEnabled: true))

Button("Cancel") { }
    .buttonStyle(SecondaryButtonStyle())

Button("Delete Account") { }
    .buttonStyle(DestructiveButtonStyle())
```

**Impact:**
- Reduces code duplication by ~500 lines
- Ensures visual consistency
- Makes future style changes trivial (change in one place)

---

### 2. **Duplicate CustomAlertView Implementation**
**Locations:** Used in 20+ files

**Problem:**
```swift
if showingAlert {
    CustomAlertView(
        title: "Error",
        description: errorMessage,
        primaryAction: { showingAlert = false },
        primaryActionTitle: "OK",
        customContent: EmptyView()
    )
    .transition(.opacity)
    .zIndex(1001)
}
```
This pattern is repeated in every view that needs to show an alert.

**Recommendation:** Create an AppState-level alert system

```swift
// In AppState.swift
@Published var alertConfig: AlertConfig?

struct AlertConfig: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let primaryAction: () -> Void
    let primaryActionTitle: String
    let cancelAction: (() -> Void)?
    let cancelActionTitle: String?
}

func showAlert(
    title: String,
    description: String,
    primaryActionTitle: String = "OK",
    primaryAction: @escaping () -> Void
) {
    alertConfig = AlertConfig(
        title: title,
        description: description,
        primaryAction: primaryAction,
        primaryActionTitle: primaryActionTitle,
        cancelAction: nil,
        cancelActionTitle: nil
    )
}
```

**Usage:**
```swift
// In any view
appState.showAlert(title: "Error", description: "Something went wrong")

// In BurnerApp.swift (single alert rendering)
if let config = appState.alertConfig {
    CustomAlertView(
        title: config.title,
        description: config.description,
        primaryAction: {
            config.primaryAction()
            appState.alertConfig = nil
        },
        primaryActionTitle: config.primaryActionTitle,
        customContent: EmptyView()
    )
}
```

---

### 3. **Duplicate Loading State Management**
**Locations:** EventViewModel, TicketsViewModel, BookmarkManager, PaymentService

**Current Pattern (Redundant):**
```swift
@Published var isLoading = false

private func startLoading() {
    withAnimation { isLoading = true }
}

private func stopLoading() {
    withAnimation { isLoading = false }
}
```

**Recommendation:** Create a LoadingState protocol or base class

```swift
protocol LoadingStateManager: ObservableObject {
    var isLoading: Bool { get set }
}

extension LoadingStateManager {
    func performWithLoading<T>(_ operation: @escaping () async throws -> T) async rethrows -> T {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { isLoading = false } } }
        return try await operation()
    }
}
```

---

### 4. **Event Row Components**
**Locations:**
- `UnifiedEventRow` in `CustomRows.swift`
- `BookmarkListItem` in `BookmarksView.swift`

**Problem:** Similar layouts with minor variations - could be unified further

**Current State:**
- `UnifiedEventRow` handles event lists and ticket rows
- `BookmarkListItem` is nearly identical but separate

**Recommendation:** Consolidate into single component with better configuration

```swift
struct EventRow: View {
    let event: Event
    let configuration: EventRowConfiguration

    struct EventRowConfiguration {
        let showBookmark: Bool
        let showQRCode: Bool
        let showVenue: Bool
        let showPrice: Bool
        let onBookmark: (() -> Void)?
        let onRemove: (() -> Void)?

        static let eventList = EventRowConfiguration(...)
        static let ticketList = EventRowConfiguration(...)
        static let bookmarkList = EventRowConfiguration(...)
    }
}
```

---

## 🏗️ ARCHITECTURE IMPROVEMENTS

### 1. **Dependency Injection**
**Current Issue:** Services and repositories are tightly coupled

**Example Problem:**
```swift
// Many ViewModels create their own dependencies
let eventRepository = EventRepository()
let ticketRepository = TicketRepository()
```

**Recommendation:** Implement proper DI container (already partially done in AppState)

- Continue consolidating all repository instances in AppState ✅
- Pass dependencies through initializers only
- Benefits: Easier testing, better modularity, clearer dependencies

---

### 2. **Navigation State Management**
**Current Issue:** Navigation is handled inconsistently across the app

**Problems:**
- Some views use `@Environment(\.presentationMode)`
- Others use `@State` variables for sheet presentation
- Deep linking uses NotificationCenter
- Tab selection is in AppState

**Recommendation:** Implement NavigationCoordinator pattern

```swift
@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var selectedTab = 0
    @Published var presentedSheet: Sheet?
    @Published var presentedAlert: AlertConfig?

    enum Sheet: Identifiable {
        case signIn
        case ticketPurchase(Event)
        case ticketDetail(TicketWithEventData)
        case passwordlessAuth

        var id: String {
            switch self {
            case .signIn: return "signIn"
            case .ticketPurchase(let event): return "purchase-\(event.id ?? "")"
            case .ticketDetail(let ticket): return "ticket-\(ticket.id)"
            case .passwordlessAuth: return "passwordless"
            }
        }
    }

    func navigate(to route: Route) { /* ... */ }
    func presentSheet(_ sheet: Sheet) { /* ... */ }
    func dismissSheet() { /* ... */ }
}
```

---

### 3. **Error Handling**
**Current Issue:** Inconsistent error handling patterns

**Problems:**
- Some errors shown in CustomAlertView
- Some errors logged to console only
- Some errors set `@Published var errorMessage`
- No centralized error tracking/reporting

**Recommendation:** Implement centralized error handling

```swift
@MainActor
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?

    enum AppError: Identifiable {
        case network(Error)
        case auth(AuthError)
        case payment(PaymentError)
        case general(String)

        var id: String { /* ... */ }
        var userMessage: String { /* ... */ }
        var shouldLog: Bool { /* ... */ }
    }

    func handle(_ error: Error, context: String? = nil) {
        // Log to analytics
        // Show user-friendly message
        // Optionally retry
    }
}
```

---

### 4. **ViewModels Too Large**
**Location:** `EventViewModel` (likely 500+ lines)

**Problem:**
- Single ViewModel handling events AND tickets AND purchases
- Violates Single Responsibility Principle

**Recommendation:** Split into focused ViewModels

```swift
// EventListViewModel - manages event browsing/filtering
// EventDetailViewModel - manages single event state
// TicketPurchaseViewModel - handles purchase flow
// TicketListViewModel - manages user's tickets
```

---

### 5. **Repository Pattern Enhancement**
**Current State:** Repositories exist but could be more robust

**Recommendations:**

#### Add Result Type
```swift
enum RepositoryResult<T> {
    case success(T)
    case failure(RepositoryError)
}

enum RepositoryError: Error {
    case network
    case notFound
    case unauthorized
    case serverError(String)
}
```

#### Add Caching Layer
```swift
protocol CacheableRepository {
    associatedtype Entity
    var cache: Cache<Entity> { get }
    func fetchWithCache(id: String) async throws -> Entity
}
```

---

### 6. **Testing Infrastructure**
**Current State:** No visible test files

**Recommendation:** Add testing infrastructure

```
burnerTests/
├── ViewModels/
│   ├── EventViewModelTests.swift
│   ├── TicketsViewModelTests.swift
├── Repositories/
│   ├── EventRepositoryTests.swift
│   ├── TicketRepositoryTests.swift
├── Services/
│   ├── StripePaymentServiceTests.swift
│   ├── AuthenticationServiceTests.swift
├── Mocks/
│   ├── MockEventRepository.swift
│   ├── MockFirebaseAuth.swift
```

---

## 🎨 UI/UX IMPROVEMENTS

### 1. **Loading States**
Many views show generic ProgressView without skeleton loaders or meaningful feedback

**Recommendation:** Implement skeleton loaders for better perceived performance

### 2. **Empty States**
Some views have good empty states (BookmarksView), others don't

**Recommendation:** Audit all list views and add consistent empty states

### 3. **Error States**
Most errors just show alert - no inline error states

**Recommendation:** Add inline error banners with retry actions

---

## 📊 PERFORMANCE OPTIMIZATIONS

### 1. **Image Loading**
Currently using KFImage (Kingfisher) - good choice ✅

**Minor Improvement:**
Add memory cache configuration in AppDelegate

### 2. **List Performance**
Using LazyVStack ✅

**Consider:**
- Add `.id()` to force refresh when needed
- Implement pagination for event lists

### 3. **Firebase Queries**
Ensure proper indexing on Firestore queries

**Recommendation:** Review Firestore rules and create composite indexes for:
- Events by date + venue
- Tickets by user + status
- Bookmarks by user + event

---

## 🔐 SECURITY CONSIDERATIONS

### 1. **Payment Security**
Stripe integration looks secure ✅

**Verify:**
- No payment method IDs exposed in logs
- Secure token handling

### 2. **Authentication**
Firebase Auth properly implemented ✅

**Consider:**
- Add app attestation for production
- Implement rate limiting for auth attempts

### 3. **Deep Links**
Current validation is good ✅

**Consider:**
- Add universal links (https://) for better sharing
- Validate all deep link parameters

---

## 📝 CODE QUALITY

### Areas of Excellence ✅
1. Consistent naming conventions
2. Good use of SwiftUI best practices
3. Proper separation of Views and ViewModels
4. Clean Avenir font system

### Areas for Improvement
1. Add more inline documentation
2. Consider SwiftLint for consistency
3. Add MARK comments for better navigation (already used well in some files)
4. Consider Swift Concurrency (async/await) more widely

---

## 🎯 PRIORITY RECOMMENDATIONS

### High Priority (Do First)
1. ✅ Fix bookmark buttons to show sign-in sheet (DONE)
2. ✅ Fix passwordless auth URL handling (DONE)
3. Fix delete account re-authentication requirement
4. Create reusable button styles to reduce duplication

### Medium Priority
1. Implement NavigationCoordinator
2. Consolidate error handling
3. Add basic unit tests for ViewModels
4. Split large ViewModels

### Low Priority (Nice to Have)
1. Implement skeleton loaders
2. Add comprehensive empty states
3. Performance optimizations (pagination, etc.)
4. Enhanced analytics/error logging

---

## 📈 METRICS

**Code Reduction Potential:**
- Button styles consolidation: ~500 lines
- Alert system consolidation: ~300 lines
- Loading state helpers: ~200 lines
- **Total estimated reduction: ~1000 lines** without losing functionality

**Maintainability Improvements:**
- Centralized styling = Faster design iterations
- Proper DI = Easier testing
- NavigationCoordinator = Clearer navigation logic

---

## ✅ CHANGES MADE IN THIS SESSION

1. **Button Homogenization**
   - Updated all button text sizes to 17pt (from 16pt) for better readability
   - Made fonts consistent across all buttons in the app

2. **Bookmark Authentication Fix**
   - Added authentication check to all bookmark buttons
   - Show sign-in sheet when unauthenticated users try to bookmark

3. **Terms & Privacy Links**
   - Added NavigationLinks to Terms of Service and Privacy Policy on sign-in sheet
   - Made legal documents easily accessible to users

4. **Passwordless Auth Integration**
   - Added PasswordlessAuthHandler to AppState
   - Integrated passwordless sign-in link handling into main app URL handler
   - Now properly handles Firebase authentication links

5. **Button Audit Complete**
   - Verified all buttons are functional or documented their issues
   - Created this comprehensive improvement document

---

**End of Report**
