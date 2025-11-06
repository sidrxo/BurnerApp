# Navigation State Coordinator Implementation

## Overview

This document describes the implementation of the **NavigationCoordinator** pattern to centralize and standardize navigation state management across the BurnerApp.

## Problem Statement

Before this implementation, navigation was handled inconsistently across the app:

- **Multiple @State variables** (42+) scattered across views for sheet/modal presentations
- **@Environment(\.presentationMode)** used in 7 different views for dismissal
- **NotificationCenter** used for deep linking and cross-view communication
- **Manual tab bar visibility** management with separate `TabBarVisibility` class
- **Mixed navigation patterns** (NavigationStack, NavigationLink, state-based modals)

This led to:
- Difficult state management
- Code duplication
- Hard to track navigation flows
- Maintenance challenges

## Solution: NavigationCoordinator Pattern

The NavigationCoordinator provides a **single source of truth** for all navigation state in the app.

### Architecture

```
┌─────────────────────────────────────────────────────┐
│                   AppState                          │
│  ┌───────────────────────────────────────────────┐ │
│  │      NavigationCoordinator                    │ │
│  │  • Tab Selection (AppTab enum)                │ │
│  │  • Navigation Paths (per tab)                 │ │
│  │  • Modal Presentations (ModalPresentation)    │ │
│  │  • Alert Presentations (AlertPresentation)    │ │
│  │  • Deep Link Handling                         │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
                        │
                        │ @EnvironmentObject
                        │
            ┌───────────┴───────────┐
            │                       │
        ┌───▼────┐             ┌────▼────┐
        │  View  │             │  View   │
        │ Layer  │             │  Layer  │
        └────────┘             └─────────┘
```

## Key Components

### 1. **NavigationCoordinator** (`burner/Navigation/NavigationCoordinator.swift`)

The main coordinator class that manages all navigation state.

**Properties:**
- `selectedTab: AppTab` - Current selected tab
- `shouldHideTabBar: Bool` - Tab bar visibility state
- `homePath`, `explorePath`, `ticketsPath`, `settingsPath` - Navigation paths per tab
- `activeModal: ModalPresentation?` - Currently presented modal
- `activeAlert: AlertPresentation?` - Currently displayed alert
- `pendingDeepLink: String?` - Pending deep link event ID
- `shouldFocusSearchBar: Bool` - Search bar focus trigger

**Key Methods:**
- `selectTab(_ tab: AppTab)` - Switch tabs
- `navigate(to destination: NavigationDestination, in tab: AppTab?)` - Navigate to a destination
- `present(_ modal: ModalPresentation)` - Present a modal
- `showAlert(_ alert: AlertPresentation)` - Show an alert
- `handleDeepLink(eventId: String)` - Handle deep link navigation
- `focusSearchBar()` - Focus the search bar in Explore tab

### 2. **AppTab** Enum

Strongly-typed tab selection replacing integer-based indexing.

```swift
enum AppTab: Int, CaseIterable {
    case home = 0
    case explore = 1
    case tickets = 2
    case settings = 3
}
```

### 3. **NavigationDestination** Enum

All possible navigation destinations in the app:

```swift
enum NavigationDestination: Hashable {
    // Events
    case eventDetail(Event)
    case eventById(String)
    case filteredEvents(EventSectionDestination)

    // Tickets
    case ticketDetail(Ticket)
    case ticketPurchase(Event)
    case transferTicket(Ticket)
    case transferTicketsList

    // Settings
    case accountDetails
    case bookmarks
    case paymentSettings
    case scanner
    case support
    case debugMenu
}
```

### 4. **ModalPresentation** Enum

All modal presentations (sheets and fullScreenCovers):

```swift
enum ModalPresentation: Identifiable {
    case signIn
    case burnerSetup
    case ticketPurchase(Event, detent: PresentationDetent)
    case ticketDetail(Ticket)
    case shareSheet(items: [Any])
    case passwordlessAuth
    case fullScreenQRCode(Ticket)
    // ... more
}
```

### 5. **AlertPresentation** Struct

Standardized alert presentations with helper methods:

```swift
struct AlertPresentation: Identifiable {
    let title: String
    let message: String
    let icon: String
    let iconColor: Color

    static func success(title: String, message: String) -> AlertPresentation
    static func error(title: String, message: String) -> AlertPresentation
    static func warning(title: String, message: String) -> AlertPresentation
    static func info(title: String, message: String) -> AlertPresentation
}
```

### 6. **NavigationCoordinatorView** (`burner/Navigation/NavigationCoordinatorView.swift`)

A wrapper view that handles modal and alert presentations:

```swift
struct NavigationCoordinatorView<Content: View>: View {
    @EnvironmentObject var coordinator: NavigationCoordinator
    @ViewBuilder let content: Content

    var body: some View {
        content
            .sheet(item: sheetBinding) { modal in ... }
            .fullScreenCover(item: fullScreenBinding) { modal in ... }
            .overlay { /* Alert presentation */ }
    }
}
```

### 7. **NavigationDestinationBuilder**

Maps NavigationDestination enum cases to actual views:

```swift
struct NavigationDestinationBuilder: View {
    let destination: NavigationDestination
    @EnvironmentObject var coordinator: NavigationCoordinator

    var body: some View {
        Group {
            switch destination {
            case .eventDetail(let event):
                EventDetailView(event: event)
            // ... other cases
            }
        }
        .onAppear { coordinator.hideTabBar() }
        .onDisappear { coordinator.showTabBar() }
    }
}
```

## Integration Points

### 1. **AppState** (`burner/App/AppState.swift`)

```swift
class AppState: ObservableObject {
    @Published var navigationCoordinator: NavigationCoordinator

    init() {
        self.navigationCoordinator = NavigationCoordinator()
        setupNavigationCoordinatorSync()
    }
}
```

### 2. **MainTabView** (`burner/Components/MainTabView.swift`)

Wraps content in NavigationCoordinatorView and provides NavigationStacks per tab:

```swift
var body: some View {
    NavigationCoordinatorView {
        ZStack {
            switch appState.navigationCoordinator.selectedTab {
            case .home:
                NavigationStack(path: $appState.navigationCoordinator.homePath) {
                    HomeView()
                        .navigationDestination(for: NavigationDestination.self) { destination in
                            NavigationDestinationBuilder(destination: destination)
                        }
                }
            // ... other tabs
            }
        }
    }
    .environmentObject(appState.navigationCoordinator)
}
```

### 3. **CustomTabBar**

Updated to use coordinator directly:

```swift
Button(action: {
    if coordinator.selectedTab == .explore {
        coordinator.focusSearchBar()
    } else {
        coordinator.selectTab(.explore)
    }
}) { ... }
```

### 4. **Deep Linking** (`burner/App/BurnerApp.swift`)

Simplified deep link handling:

```swift
private func navigateToEvent(eventId: String) {
    appState.navigationCoordinator.handleDeepLink(eventId: eventId)
}
```

### 5. **Views**

Views now use the coordinator for all navigation:

**Before:**
```swift
@State private var showingPurchase = false
@Environment(\.presentationMode) var presentationMode

Button("Buy") {
    showingPurchase = true
}
.sheet(isPresented: $showingPurchase) {
    TicketPurchaseView(event: event)
}
```

**After:**
```swift
@EnvironmentObject var coordinator: NavigationCoordinator

Button("Buy") {
    coordinator.purchaseTicket(for: event)
}
```

## Benefits

### 1. **Centralized State Management**
- All navigation state in one place
- Easy to debug and trace navigation flows
- Consistent state updates

### 2. **Type Safety**
- Strongly-typed enums for tabs and destinations
- Compile-time checking of navigation routes
- No more magic strings or integers

### 3. **Reduced Code Duplication**
- No more scattered @State variables
- Reusable navigation methods
- Consistent modal presentation patterns

### 4. **Improved Testability**
- Easy to mock NavigationCoordinator
- Clear navigation boundaries
- Predictable state transitions

### 5. **Better Deep Linking**
- Direct method calls instead of NotificationCenter
- Centralized deep link handling
- Easier to add new deep link routes

### 6. **Simplified Tab Bar Management**
- Automatic tab bar hiding/showing
- No manual TabBarVisibility management
- Consistent behavior across views

## Migration Status

### ✅ Completed
- NavigationCoordinator implementation
- MainTabView integration
- Deep linking (BurnerApp.swift)
- HomeView (ExploreView.swift)
- ExploreView (SearchView.swift)
- EventDetailView
- CustomTabBar
- Tab bar visibility management

### 🔄 Remaining (Optional)
- SettingsView and sub-views
- TicketDetailView
- TicketPurchaseView
- TransferTicketView
- Other modal presentations

## Usage Examples

### Navigate to Event Detail
```swift
coordinator.navigate(to: .eventDetail(event))
```

### Show Purchase Modal
```swift
coordinator.purchaseTicket(for: event)
```

### Show Alert
```swift
coordinator.showSuccess(title: "Success", message: "Ticket purchased!")
coordinator.showError(title: "Error", message: "Purchase failed")
```

### Switch Tab
```swift
coordinator.selectTab(.tickets)
```

### Handle Deep Link
```swift
coordinator.handleDeepLink(eventId: "event123")
```

### Share Event
```swift
coordinator.shareEvent(event)
```

## Future Enhancements

1. **Navigation History**
   - Track navigation history
   - Implement back/forward navigation
   - Save/restore navigation state

2. **Analytics Integration**
   - Track all navigation events
   - Monitor user flows
   - Analyze navigation patterns

3. **Conditional Navigation**
   - Authentication checks
   - Permission-based routing
   - Feature flags

4. **Animation Control**
   - Custom transitions
   - Coordinated animations
   - Screen-specific effects

## Backward Compatibility

The implementation maintains backward compatibility during migration:
- Old `selectedTab: Int` is kept in sync with new `AppTab` enum
- Old `isSignInSheetPresented` is synced with coordinator modal state
- Existing views continue to work while being migrated incrementally

## Testing

To test the NavigationCoordinator:

1. **Tab Navigation**: Switch between all tabs
2. **Deep Linking**: Test event deep links
3. **Modal Presentations**: Open purchase sheets, share sheets
4. **Alerts**: Trigger success/error alerts
5. **Search Focus**: Double-tap Explore tab
6. **Tab Bar Visibility**: Verify hiding/showing on navigation

## Conclusion

The NavigationCoordinator pattern provides a robust, scalable solution for navigation state management in BurnerApp. It eliminates inconsistencies, reduces code duplication, and provides a clear, type-safe API for all navigation operations.
