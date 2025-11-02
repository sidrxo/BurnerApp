# iOS Testing Guide for BurnerApp

## Overview

This document provides comprehensive guidance for implementing unit tests for the BurnerApp iOS application. Currently, the iOS codebase does not have an Xcode project file (`.xcodeproj` or `.xcworkspace`), which is required to set up and run XCTest-based unit tests.

## Prerequisites

Before implementing unit tests, you need:

1. **Xcode Project Setup**: Create or locate the `.xcodeproj` or `.xcworkspace` file
2. **XCTest Framework**: Built into Xcode (no additional installation needed)
3. **Test Target**: Add a test target to your Xcode project

## Setting Up Testing Infrastructure

### Step 1: Create Test Target

1. Open your project in Xcode
2. Go to **File > New > Target**
3. Select **iOS Unit Testing Bundle**
4. Name it `BurnerAppTests`
5. Ensure it's added to your main app target

### Step 2: Project Structure

Organize your tests to mirror your source code structure:

```
burner/
├── App/
├── Components/
├── Extensions/
│   ├── Models/
│   ├── Repositories/
│   ├── Services/
│   └── Managers/
├── Settings/
├── Tickets/
└── BurnerAppTests/          # New test directory
    ├── Services/
    ├── Managers/
    ├── Repositories/
    ├── Models/
    └── Helpers/
```

## Critical Areas to Test

### Priority 1: Services (High Business Logic)

#### 1. AuthenticationService Tests
File: `BurnerAppTests/Services/AuthenticationServiceTests.swift`

```swift
import XCTest
@testable import BurnerApp

class AuthenticationServiceTests: XCTestCase {
    var sut: AuthenticationService!

    override func setUp() {
        super.setUp()
        sut = AuthenticationService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // Test Cases to Implement:

    func testSignInWithEmail_ValidCredentials_Success() {
        // Test successful email/password sign-in
    }

    func testSignInWithEmail_InvalidCredentials_Failure() {
        // Test failed authentication
    }

    func testSignInWithGoogle_Success() {
        // Test Google OAuth flow
    }

    func testSignOut_Success() {
        // Test sign-out functionality
    }

    func testCheckUserRole_SiteAdmin_ReturnsTrue() {
        // Test role checking for siteAdmin
    }

    func testCheckUserRole_VenueAdmin_ReturnsTrue() {
        // Test role checking for venueAdmin
    }

    func testCheckUserRole_NoRole_ReturnsFalse() {
        // Test role checking for user without role
    }

    func testRefreshCustomClaims_UpdatesUserClaims() {
        // Test token refresh updates custom claims
    }

    func testIsAuthenticated_WithValidUser_ReturnsTrue() {
        // Test authentication state check
    }

    func testIsAuthenticated_WithNoUser_ReturnsFalse() {
        // Test authentication state when not logged in
    }
}
```

#### 2. PurchaseService Tests
File: `BurnerAppTests/Services/PurchaseServiceTests.swift`

```swift
import XCTest
@testable import BurnerApp

class PurchaseServiceTests: XCTestCase {
    var sut: PurchaseService!
    var mockEvent: Event!

    override func setUp() {
        super.setUp()
        sut = PurchaseService()
        mockEvent = Event(
            id: "event123",
            name: "Test Event",
            price: 50.0,
            maxTickets: 100,
            ticketsSold: 50
        )
    }

    // Test Cases to Implement:

    func testInitiatePurchase_ValidEvent_CreatesPaymentIntent() {
        // Test payment intent creation
    }

    func testInitiatePurchase_SoldOutEvent_ThrowsError() {
        // Test error handling for sold-out events
    }

    func testInitiatePurchase_UserAlreadyHasTicket_ThrowsError() {
        // Test duplicate purchase prevention
    }

    func testConfirmPurchase_ValidPayment_CreatesTicket() {
        // Test successful ticket creation after payment
    }

    func testConfirmPurchase_PaymentFailed_DoesNotCreateTicket() {
        // Test error handling for failed payments
    }

    func testValidateTicketAvailability_AvailableTickets_ReturnsTrue() {
        // Test ticket availability check
    }

    func testValidateTicketAvailability_NoTicketsLeft_ReturnsFalse() {
        // Test sold-out detection
    }

    func testCalculateTotalPrice_IncludesEventPrice() {
        // Test price calculation
    }
}
```

#### 3. StripePaymentService Tests
File: `BurnerAppTests/Services/StripePaymentServiceTests.swift`

```swift
import XCTest
@testable import BurnerApp

class StripePaymentServiceTests: XCTestCase {
    var sut: StripePaymentService!

    override func setUp() {
        super.setUp()
        sut = StripePaymentService()
    }

    // Test Cases to Implement:

    func testCreatePaymentIntent_ValidAmount_ReturnsIntent() {
        // Test payment intent creation
    }

    func testCreatePaymentIntent_InvalidAmount_ThrowsError() {
        // Test validation for invalid amounts
    }

    func testConfirmPaymentWithApplePay_ValidToken_Success() {
        // Test Apple Pay payment confirmation
    }

    func testConfirmPaymentWithCard_ValidCard_Success() {
        // Test card payment confirmation
    }

    func testSavePaymentMethod_ValidMethod_SavesSuccessfully() {
        // Test payment method storage
    }

    func testGetPaymentMethods_ReturnsUserMethods() {
        // Test retrieving saved payment methods
    }

    func testDeletePaymentMethod_RemovesMethod() {
        // Test payment method deletion
    }
}
```

### Priority 2: Managers (State Management)

#### 1. BookmarkManager Tests
File: `BurnerAppTests/Managers/BookmarkManagerTests.swift`

```swift
import XCTest
@testable import BurnerApp

class BookmarkManagerTests: XCTestCase {
    var sut: BookmarkManager!

    override func setUp() {
        super.setUp()
        sut = BookmarkManager()
    }

    // Test Cases:

    func testAddBookmark_NewEvent_AddsToCollection() {}
    func testRemoveBookmark_ExistingEvent_RemovesFromCollection() {}
    func testIsBookmarked_ExistingBookmark_ReturnsTrue() {}
    func testIsBookmarked_NoBookmark_ReturnsFalse() {}
    func testFetchBookmarks_ReturnsUserBookmarks() {}
    func testToggleBookmark_NotBookmarked_AddsBookmark() {}
    func testToggleBookmark_AlreadyBookmarked_RemovesBookmark() {}
}
```

#### 2. BurnerModeManager Tests
File: `BurnerAppTests/Managers/BurnerModeManagerTests.swift`

```swift
import XCTest
@testable import BurnerApp

class BurnerModeManagerTests: XCTestCase {
    var sut: BurnerModeManager!

    // Test Cases:

    func testEnableBurnerMode_UpdatesState() {}
    func testDisableBurnerMode_UpdatesState() {}
    func testIsBurnerModeEnabled_ReturnsCorrectState() {}
    func testBurnerModeRequiresAuthentication_WhenEnabled() {}
    func testLockScreenState_WhenBurnerModeActive() {}
}
```

#### 3. OnboardingManager Tests
File: `BurnerAppTests/Managers/OnboardingManagerTests.swift`

```swift
import XCTest
@testable import BurnerApp

class OnboardingManagerTests: XCTestCase {
    var sut: OnboardingManager!

    // Test Cases:

    func testIsOnboardingComplete_FirstLaunch_ReturnsFalse() {}
    func testIsOnboardingComplete_CompletedOnboarding_ReturnsTrue() {}
    func testCompleteOnboarding_UpdatesUserDefaults() {}
    func testResetOnboarding_ClearsCompletionFlag() {}
    func testOnboardingStep_TracksProgress() {}
}
```

### Priority 3: Repositories (Data Access Layer)

#### 1. EventRepository Tests
File: `BurnerAppTests/Repositories/EventRepositoryTests.swift`

```swift
import XCTest
@testable import BurnerApp

class EventRepositoryTests: XCTestCase {
    var sut: EventRepository!

    // Test Cases:

    func testFetchEvents_ReturnsAllEvents() {}
    func testFetchEvent_ValidID_ReturnsEvent() {}
    func testFetchEvent_InvalidID_ReturnsNil() {}
    func testFilterEventsByCategory_ReturnsFilteredEvents() {}
    func testSearchEvents_ByName_ReturnsMatchingEvents() {}
    func testFetchFeaturedEvents_ReturnsOnlyFeatured() {}
    func testSortEventsByDate_ReturnsChronologicalOrder() {}
}
```

#### 2. TicketRepository Tests
File: `BurnerAppTests/Repositories/TicketRepositoryTests.swift`

```swift
import XCTest
@testable import BurnerApp

class TicketRepositoryTests: XCTestCase {
    var sut: TicketRepository!

    // Test Cases:

    func testFetchUserTickets_ReturnsAllTickets() {}
    func testFetchTicket_ValidID_ReturnsTicket() {}
    func testCreateTicket_ValidData_CreatesTicket() {}
    func testUpdateTicketStatus_ValidStatus_Updates() {}
    func testDeleteTicket_RemovesFromDatabase() {}
    func testFilterTicketsByStatus_ReturnsFilteredTickets() {}
}
```

#### 3. UserRepository Tests
File: `BurnerAppTests/Repositories/UserRepositoryTests.swift`

```swift
import XCTest
@testable import BurnerApp

class UserRepositoryTests: XCTestCase {
    var sut: UserRepository!

    // Test Cases:

    func testFetchUserProfile_ValidID_ReturnsProfile() {}
    func testUpdateUserProfile_UpdatesDatabase() {}
    func testCreateUserProfile_NewUser_CreatesProfile() {}
    func testDeleteUserProfile_RemovesFromDatabase() {}
}
```

### Priority 4: Models (Data Structures)

#### Models Tests
File: `BurnerAppTests/Models/ModelsTests.swift`

```swift
import XCTest
@testable import BurnerApp

class EventModelTests: XCTestCase {
    // Test Cases:

    func testEventInitialization_ValidData_CreatesEvent() {}
    func testEventCodable_EncodesAndDecodes() {}
    func testEventValidation_ValidData_Passes() {}
    func testIsTicketAvailable_WithAvailableTickets_ReturnsTrue() {}
    func testIsSoldOut_WhenFullySold_ReturnsTrue() {}
}

class TicketModelTests: XCTestCase {
    // Test Cases:

    func testTicketInitialization_ValidData_CreatesTicket() {}
    func testTicketCodable_EncodesAndDecodes() {}
    func testTicketStatus_ValidTransition_Updates() {}
    func testQRCodeGeneration_GeneratesValidQRCode() {}
}

class VenueModelTests: XCTestCase {
    // Test Cases:

    func testVenueInitialization_ValidData_CreatesVenue() {}
    func testVenueCodable_EncodesAndDecodes() {}
}
```

## Mocking and Test Doubles

### Firebase Mocking

Create mock implementations for Firebase services:

```swift
// BurnerAppTests/Mocks/MockFirestore.swift
class MockFirestore {
    var mockDocuments: [String: Any] = [:]
    var mockCollections: [String: [Any]] = [:]

    func collection(_ name: String) -> MockCollectionReference {
        return MockCollectionReference(name: name, firestore: self)
    }
}

// BurnerAppTests/Mocks/MockAuth.swift
class MockAuth {
    var mockCurrentUser: MockUser?
    var shouldSucceed: Bool = true

    func signIn(email: String, password: String) async throws -> MockUser {
        if shouldSucceed {
            mockCurrentUser = MockUser(uid: "test-uid", email: email)
            return mockCurrentUser!
        } else {
            throw NSError(domain: "AuthError", code: -1)
        }
    }
}
```

## Running Tests

### Command Line
```bash
xcodebuild test \
  -project BurnerApp.xcodeproj \
  -scheme BurnerApp \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'
```

### Xcode
1. Press `Cmd + U` to run all tests
2. Or click the diamond icon next to test methods to run individual tests

## Code Coverage

### Enable Code Coverage in Xcode:
1. Edit your scheme (Product > Scheme > Edit Scheme)
2. Select "Test" from the sidebar
3. Check "Gather coverage for all targets"
4. Run tests

### View Coverage Report:
1. After running tests with coverage enabled
2. Open Report Navigator (Cmd + 9)
3. Select the latest test report
4. Click the "Coverage" tab

### Target Coverage Thresholds:
- **Services**: 85%+ coverage
- **Managers**: 80%+ coverage
- **Repositories**: 80%+ coverage
- **Models**: 90%+ coverage (mostly data structures)
- **Overall Project**: 70%+ coverage

## Continuous Integration

### GitHub Actions Example

Create `.github/workflows/ios-tests.yml`:

```yaml
name: iOS Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3

    - name: Select Xcode version
      run: sudo xcode-select -s /Applications/Xcode_15.0.app

    - name: Run tests
      run: |
        xcodebuild test \
          -project BurnerApp.xcodeproj \
          -scheme BurnerApp \
          -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
          -enableCodeCoverage YES

    - name: Generate code coverage report
      run: |
        xcrun xccov view --report --json \
          ~/Library/Developer/Xcode/DerivedData/BurnerApp-*/Logs/Test/*.xcresult > coverage.json
```

## Best Practices

### 1. Test Naming Convention
```swift
func test_MethodName_Scenario_ExpectedResult()
```

### 2. Arrange-Act-Assert Pattern
```swift
func testPurchaseTicket_ValidEvent_CreatesTicket() {
    // Arrange
    let event = Event(id: "1", name: "Test", price: 50)
    let sut = PurchaseService()

    // Act
    let result = sut.purchaseTicket(event: event)

    // Assert
    XCTAssertNotNil(result)
    XCTAssertEqual(result.eventId, "1")
}
```

### 3. Test Isolation
- Each test should be independent
- Use `setUp()` and `tearDown()` properly
- Don't rely on test execution order

### 4. Async Testing
```swift
func testAsyncOperation() async throws {
    let expectation = XCTestExpectation(description: "Async operation")

    await sut.performAsyncOperation { result in
        XCTAssertTrue(result.success)
        expectation.fulfill()
    }

    await fulfillment(of: [expectation], timeout: 5.0)
}
```

### 5. Error Testing
```swift
func testMethod_InvalidInput_ThrowsError() {
    XCTAssertThrowsError(try sut.method(invalid: input)) { error in
        XCTAssertTrue(error is ValidationError)
    }
}
```

## Test Data Management

### Create Test Fixtures
```swift
// BurnerAppTests/Fixtures/EventFixtures.swift
struct EventFixtures {
    static let validEvent = Event(
        id: "event-1",
        name: "Test Event",
        price: 50.0,
        maxTickets: 100,
        ticketsSold: 0
    )

    static let soldOutEvent = Event(
        id: "event-2",
        name: "Sold Out Event",
        price: 50.0,
        maxTickets: 100,
        ticketsSold: 100
    )
}
```

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing in Xcode](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/)
- [Unit Testing Best Practices](https://www.swiftbysundell.com/articles/unit-testing-best-practices/)
- [Firebase iOS Testing](https://firebase.google.com/docs/ios/unit-tests)

## Next Steps

1. Create Xcode project if not exists
2. Add test target to project
3. Implement tests starting with Priority 1 (Services)
4. Set up CI/CD pipeline
5. Establish code coverage requirements
6. Integrate tests into development workflow

## Estimated Testing Effort

- **Services**: ~2-3 days
- **Managers**: ~1-2 days
- **Repositories**: ~1-2 days
- **Models**: ~1 day
- **Setup & CI/CD**: ~1 day

**Total**: ~6-9 days for comprehensive iOS unit test coverage
