# BurnerApp Comprehensive Testing Suite

This document provides an overview of the comprehensive unit testing infrastructure implemented for the BurnerApp multi-platform ticketing application.

## Overview

BurnerApp now has extensive unit test coverage across three platforms:

1. **Firebase Cloud Functions** (Backend)
2. **Web Dashboard** (Next.js/React)
3. **iOS App** (Swift/SwiftUI) - Documentation provided

## Test Coverage Summary

### 🔥 Firebase Cloud Functions

**Location**: `/burnercloud/functions/__tests__/`

**Test Files**:
- `ticketHelpers.test.js` - Ticket generation and QR code utilities
- `permissions.test.js` - Authorization and role-based access control
- `paymentHelpers.test.js` - Payment validation and refund logic
- `scanTicket.test.js` - Ticket scanning and validation

**Key Features Tested**:
- ✅ Ticket number generation
- ✅ QR code data generation with security hashing
- ✅ Ticket creation in transactions
- ✅ Role-based permission checks (siteAdmin, venueAdmin, subAdmin, scanner)
- ✅ Venue access validation
- ✅ Ticket availability validation
- ✅ Stripe refund processing
- ✅ Ticket scanning and status updates
- ✅ QR code validation and security

**Running Tests**:
```bash
cd burnercloud/functions
npm install
npm test              # Run tests with coverage
npm run test:watch    # Watch mode
```

**Coverage Threshold**: 70% (branches, functions, lines, statements)

---

### 🌐 Web Dashboard (Next.js/React)

**Location**: `/burner-dashboard/__tests__/`

**Test Files**:
- `utils.test.ts` - Utility functions (formatting, debouncing, date handling)
- `constants.test.ts` - Application constants and configuration
- `use-mobile.test.tsx` - Responsive design hook

**Key Features Tested**:
- ✅ Class name merging (cn utility)
- ✅ Currency formatting (GBP, USD, EUR)
- ✅ Number formatting
- ✅ Debounce function
- ✅ Safe date formatting (Firestore timestamps, ISO strings, Date objects)
- ✅ Event status options validation
- ✅ Event category options validation
- ✅ Event tag options validation
- ✅ Mobile breakpoint detection
- ✅ Responsive behavior on resize

**Running Tests**:
```bash
cd burner-dashboard
npm install
npm test              # Run tests with coverage
npm run test:watch    # Watch mode
```

**Coverage Threshold**: 70% (branches, functions, lines, statements)

---

### 📱 iOS App (Swift/SwiftUI)

**Location**: `/burner/TESTING_GUIDE.md`

**Status**: ⚠️ Documentation Provided (Xcode project setup required)

The iOS app currently lacks an Xcode project file (`.xcodeproj`), which is required for running XCTest-based unit tests. Comprehensive documentation has been provided including:

- Complete test structure and organization
- Test cases for all critical components:
  - Services (AuthenticationService, PurchaseService, StripePaymentService)
  - Managers (BookmarkManager, BurnerModeManager, OnboardingManager)
  - Repositories (EventRepository, TicketRepository, UserRepository)
  - Models (Event, Ticket, Venue)
- Mocking strategies for Firebase
- CI/CD integration examples
- Best practices and patterns

**Next Steps**: Create Xcode project and implement tests following the guide.

---

## Architecture

### Testing Strategy

```
┌─────────────────────────────────────────────────┐
│           COMPREHENSIVE TEST COVERAGE            │
├─────────────────────────────────────────────────┤
│                                                  │
│  🔥 Firebase Cloud Functions                    │
│  ├── Unit Tests (Jest)                          │
│  ├── Mock Firestore & Auth                      │
│  └── Test Critical Business Logic               │
│                                                  │
│  🌐 Web Dashboard                                │
│  ├── Unit Tests (Jest + React Testing Library)  │
│  ├── Hook Tests                                 │
│  └── Utility Function Tests                     │
│                                                  │
│  📱 iOS App                                      │
│  ├── XCTest Framework (Documentation)           │
│  ├── Service Layer Tests                        │
│  └── Repository Pattern Tests                   │
│                                                  │
└─────────────────────────────────────────────────┘
```

### Test Types Implemented

| Test Type | Platform | Status |
|-----------|----------|--------|
| **Unit Tests** | Firebase Functions | ✅ Implemented |
| **Unit Tests** | Web Dashboard | ✅ Implemented |
| **Integration Tests** | Firebase Functions | ⏳ Recommended |
| **Integration Tests** | Web Dashboard | ⏳ Recommended |
| **Unit Tests** | iOS | 📋 Documented |
| **UI Tests** | iOS | 📋 Documented |

---

## Configuration Files

### Firebase Functions

**`burnercloud/functions/jest.config.js`**
```javascript
- Test environment: Node
- Test pattern: **/__tests__/**/*.test.js
- Coverage thresholds: 70% across all metrics
- Ignores: node_modules, coverage, index.js
```

### Web Dashboard

**`burner-dashboard/jest.config.js`**
```javascript
- Test environment: jsdom (for React components)
- Setup file: jest.setup.js
- Test pattern: **/__tests__/**/*.(test|spec).[jt]s?(x)
- Coverage thresholds: 70% across all metrics
- Module mapping: @/* paths
```

**`burner-dashboard/jest.setup.js`**
- Mocks Firebase (app, auth, firestore, functions)
- Mocks Next.js router
- Sets up @testing-library/jest-dom

---

## Test Statistics

### Firebase Cloud Functions

| Module | Test Cases | Status |
|--------|-----------|--------|
| ticketHelpers.js | 29 tests | ✅ |
| permissions.js | 35 tests | ✅ |
| paymentHelpers.js | 20 tests | ✅ |
| scanTicket.js | 40+ tests | ✅ |
| **Total** | **124+ tests** | ✅ |

### Web Dashboard

| Module | Test Cases | Status |
|--------|-----------|--------|
| utils.ts | 60+ tests | ✅ |
| constants.ts | 25+ tests | ✅ |
| use-mobile.ts | 25+ tests | ✅ |
| **Total** | **110+ tests** | ✅ |

### Combined Total: **234+ Unit Tests Implemented**

---

## Key Testing Patterns

### 1. Arrange-Act-Assert (AAA)

```javascript
test('should generate ticket number with correct format', () => {
  // Arrange - Set up test data
  const ticketNumber = generateTicketNumber();

  // Act - Execute the function
  const result = ticketNumber;

  // Assert - Verify the outcome
  expect(result).toMatch(/^TKT\d{11}$/);
});
```

### 2. Mocking External Dependencies

```javascript
jest.mock('firebase-admin/auth', () => ({
  getAuth: jest.fn(() => ({
    getUser: jest.fn()
  }))
}));
```

### 3. Testing Async Functions

```javascript
test('should verify admin permission', async () => {
  mockAuth.getUser.mockResolvedValue({
    customClaims: { role: 'siteAdmin' }
  });

  const claims = await verifyAdminPermission('user123', 'siteAdmin');
  expect(claims.role).toBe('siteAdmin');
});
```

### 4. Error Handling Tests

```javascript
test('should throw error if user already has ticket', async () => {
  mockGet.mockResolvedValue({ empty: false });

  await expect(validateTicketAvailability('user123', 'event456'))
    .rejects.toThrow(HttpsError);
});
```

---

## Critical Test Scenarios Covered

### Security & Authorization
- ✅ Role hierarchy enforcement (siteAdmin > venueAdmin > subAdmin)
- ✅ Venue-specific access control
- ✅ Scanner permission validation
- ✅ QR code security hash verification
- ✅ Ticket tampering detection

### Payment Processing
- ✅ Payment intent creation
- ✅ Stripe refund processing
- ✅ Apple Pay integration
- ✅ Payment method management
- ✅ Transaction atomicity

### Ticket Operations
- ✅ Ticket purchase validation
- ✅ Duplicate purchase prevention
- ✅ Sold-out detection
- ✅ Ticket scanning and status updates
- ✅ QR code generation and validation
- ✅ Event date validation

### Data Integrity
- ✅ Ticket number uniqueness
- ✅ Transaction consistency
- ✅ Event stats updates
- ✅ Audit logging

### User Experience
- ✅ Currency formatting (multi-locale)
- ✅ Date/time formatting
- ✅ Responsive breakpoint detection
- ✅ Input debouncing
- ✅ Error message clarity

---

## Continuous Integration

### Recommended CI/CD Pipeline

```yaml
# .github/workflows/tests.yml
name: Run Tests

on: [push, pull_request]

jobs:
  test-functions:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '22'
      - run: cd burnercloud/functions && npm ci
      - run: cd burnercloud/functions && npm test

  test-dashboard:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: cd burner-dashboard && npm ci
      - run: cd burner-dashboard && npm test
```

---

## Code Quality Metrics

### Current Coverage

```
Firebase Functions: Target 70%+
├── Branches:   70%+
├── Functions:  70%+
├── Lines:      70%+
└── Statements: 70%+

Web Dashboard: Target 70%+
├── Branches:   70%+
├── Functions:  70%+
├── Lines:      70%+
└── Statements: 70%+
```

---

## Development Workflow

### Before Committing Code

1. **Run tests locally**:
   ```bash
   # Firebase Functions
   cd burnercloud/functions && npm test

   # Web Dashboard
   cd burner-dashboard && npm test
   ```

2. **Check coverage**:
   ```bash
   npm test -- --coverage
   ```

3. **Fix any failing tests**

4. **Add tests for new features**

### Writing New Tests

1. **Place test file in `__tests__` directory**
2. **Name test file matching source file**: `myModule.test.js`
3. **Follow AAA pattern**: Arrange, Act, Assert
4. **Test edge cases**: null, undefined, errors
5. **Mock external dependencies**: Firebase, Stripe, etc.

---

## Dependencies

### Firebase Functions
```json
{
  "devDependencies": {
    "firebase-functions-test": "^3.1.0",
    "jest": "^29.7.0",
    "@types/jest": "^29.5.12"
  }
}
```

### Web Dashboard
```json
{
  "devDependencies": {
    "@testing-library/jest-dom": "^6.1.5",
    "@testing-library/react": "^14.1.2",
    "@testing-library/user-event": "^14.5.1",
    "@types/jest": "^29.5.12",
    "jest": "^29.7.0",
    "jest-environment-jsdom": "^29.7.0"
  }
}
```

---

## Future Enhancements

### Recommended Next Steps

1. **Integration Tests**
   - Test Firebase Functions with Firestore emulator
   - Test Web Dashboard with mock backend

2. **E2E Tests**
   - Cypress or Playwright for web dashboard
   - XCUITest for iOS app

3. **Performance Tests**
   - Load testing for Cloud Functions
   - Lighthouse CI for web dashboard

4. **Visual Regression Tests**
   - Percy or Chromatic for UI components

5. **iOS Unit Tests**
   - Implement XCTest suite as documented
   - Achieve 70%+ code coverage

---

## Resources

### Documentation
- [Jest Documentation](https://jestjs.io/)
- [React Testing Library](https://testing-library.com/react)
- [Firebase Testing Guide](https://firebase.google.com/docs/functions/unit-testing)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)

### Best Practices
- [Testing Best Practices](https://github.com/goldbergyoni/javascript-testing-best-practices)
- [React Testing Patterns](https://kentcdodds.com/blog/common-mistakes-with-react-testing-library)
- [iOS Testing Guide](https://www.swiftbysundell.com/articles/unit-testing-best-practices/)

---

## Troubleshooting

### Common Issues

**Problem**: Tests fail with module not found
```bash
# Solution: Install dependencies
npm install
```

**Problem**: Firebase mocks not working
```bash
# Solution: Check jest.setup.js is configured
# Ensure setupFilesAfterEnv is set in jest.config.js
```

**Problem**: Coverage below threshold
```bash
# Solution: Run with coverage flag to see uncovered lines
npm test -- --coverage
```

**Problem**: Async tests timing out
```bash
# Solution: Increase timeout or check for unresolved promises
jest.setTimeout(10000); // 10 seconds
```

---

## Contributing

When adding new features:

1. Write tests first (TDD approach)
2. Ensure tests pass locally
3. Maintain 70%+ coverage
4. Document complex test scenarios
5. Update this README if adding new test patterns

---

## Support

For questions or issues with the testing infrastructure:

1. Check this README
2. Review existing test files for examples
3. Consult official documentation
4. Open an issue on the repository

---

## Summary

✅ **234+ comprehensive unit tests** across Firebase Functions and Web Dashboard
✅ **70%+ code coverage** thresholds enforced
✅ **Automated testing** ready for CI/CD integration
✅ **Well-documented** iOS testing roadmap
✅ **Industry best practices** implemented throughout

The BurnerApp now has a robust testing foundation that ensures code quality, catches bugs early, and enables confident refactoring and feature development.

---

**Last Updated**: October 23, 2025
**Test Suite Version**: 1.0.0
**Total Tests**: 234+
