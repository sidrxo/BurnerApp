# Android Version Guide for Burner App

## Overview
This document outlines the process and considerations for creating an Android version of the Burner iOS app. The iOS app is currently built with SwiftUI and uses various iOS-specific frameworks and services.

## Current iOS Tech Stack

### Core Frameworks
- **SwiftUI** - Declarative UI framework
- **Firebase Suite**:
  - Firebase Auth (authentication)
  - Firebase Firestore (database)
  - Firebase Functions (cloud functions)
- **Stripe SDK** - Payment processing
- **Google Sign-In** - OAuth authentication
- **Kingfisher** - Image loading and caching
- **CodeScanner** - QR/barcode scanning

### iOS-Specific Features
- **WidgetKit** - Home screen widgets for tickets
- **ActivityKit** - Live Activities for active tickets
- **Family Controls Framework** - "Burner Mode" lock screen functionality
- **ManagedSettings & DeviceActivity** - Screen time restrictions

## Android Equivalent Technologies

### 1. UI Framework
**Options:**
- **Jetpack Compose** (recommended) - Modern declarative UI, similar to SwiftUI
- **XML Layouts + View Binding** - Traditional Android approach

**Recommendation:** Use Jetpack Compose for consistency with SwiftUI patterns and modern Android development.

### 2. Backend Services (Direct Equivalents)
- **Firebase Android SDK** - All Firebase services (Auth, Firestore, Functions) have native Android support
- **Stripe Android SDK** - Native payment processing library
- **Google Sign-In for Android** - OAuth authentication
- **Coil or Glide** - Image loading (equivalent to Kingfisher)
- **ML Kit Barcode Scanning** or **ZXing** - QR/barcode scanning

### 3. Platform-Specific Feature Replacements

#### Widgets
- **App Widgets (Glance for Compose)** - Home screen widgets
- Modern implementation with Jetpack Glance API

#### Live Activities → Live Tiles/Notifications
- No direct equivalent to iOS Live Activities
- **Options:**
  - Rich push notifications with custom layouts
  - Status bar notifications with custom views
  - Combination of widgets + notifications

#### Burner Mode Lock Screen
iOS uses Family Controls framework for device restrictions. Android alternatives:
- **Device Policy Manager (DPM)** - For kiosk mode/app pinning
- **Digital Wellbeing API** - Usage tracking and app timers
- **Custom lock overlay** - Activity with `TYPE_APPLICATION_OVERLAY` window
- **Note:** Some features require device admin permissions or special system-level access

## Development Roadmap

### Phase 1: Foundation (Weeks 1-4)
1. **Project Setup**
   - Create new Android Studio project with Kotlin
   - Set up Jetpack Compose
   - Configure Firebase Android SDK
   - Set up dependency injection (Hilt/Koin)

2. **Architecture**
   - Implement MVVM or MVI architecture
   - Set up repository pattern for data layer
   - Create models matching iOS data structures

3. **Core Services**
   - Firebase Authentication integration
   - Firebase Firestore database layer
   - Network layer for Firebase Functions
   - Stripe payment integration

### Phase 2: Core Features (Weeks 5-8)
1. **Authentication Flow**
   - Google Sign-In integration
   - Passwordless authentication
   - User session management
   - First-launch flow

2. **Event Discovery (ExploreView)**
   - Featured events hero cards
   - Location-based event search
   - Distance calculation and display
   - Event filtering

3. **Search Functionality**
   - Event search implementation
   - Search results display
   - Search history

### Phase 3: Ticket Features (Weeks 9-12)
1. **Ticket Purchase Flow**
   - Event details view
   - Stripe payment integration
   - Google Pay support (Android equivalent to Apple Pay)
   - Payment confirmation and error handling

2. **Ticket Management**
   - Purchased tickets list
   - QR code generation for tickets
   - Ticket details view
   - QR code scanning for validation

### Phase 4: Advanced Features (Weeks 13-16)
1. **Widgets**
   - Ticket widget using Jetpack Glance
   - Widget configuration
   - Auto-updates for ticket status

2. **Burner Mode**
   - Lock screen overlay
   - Timer functionality
   - Long-press exit mechanism
   - Event countdown timer
   - Consider permissions and user experience differences

3. **Settings & Preferences**
   - Settings screen with Material Design
   - Debug menu
   - User preferences storage (SharedPreferences/DataStore)

### Phase 5: Polish & Testing (Weeks 17-20)
1. **UI/UX Refinement**
   - Material Design theming
   - Animations and transitions
   - Dark mode support
   - Responsive layouts for tablets

2. **Testing**
   - Unit tests for business logic
   - UI tests with Compose Testing
   - Integration tests
   - Payment testing (test mode)

3. **Performance**
   - Image loading optimization
   - Database query optimization
   - App startup time
   - Memory management

## Key Implementation Differences

### 1. Payment Flow
**iOS (Apple Pay):**
- Native sheet with biometric auth
- Handled by PassKit framework

**Android (Google Pay):**
- Google Pay API integration
- Tap to Pay on Android for NFC
- Fallback to Stripe card entry

### 2. Real-time Updates
For the "sold out" event update issue:
- Implement Firestore real-time listeners
- Update UI reactively when event status changes
- Use StateFlow/LiveData for reactive state management

### 3. Background Updates
- Use WorkManager for periodic ticket updates
- Implement Firebase Cloud Messaging for push notifications
- Widget updates via WorkManager

### 4. Location Services
- Google Play Services Location API
- Permissions handling (runtime permissions required)
- Background location considerations

## Project Structure
```
app/
├── src/
│   ├── main/
│   │   ├── java/com/yourapp/burner/
│   │   │   ├── ui/
│   │   │   │   ├── explore/         (ExploreView equivalent)
│   │   │   │   ├── search/          (SearchView equivalent)
│   │   │   │   ├── tickets/         (Ticket screens)
│   │   │   │   ├── settings/        (Settings screens)
│   │   │   │   ├── components/      (Reusable UI components)
│   │   │   │   └── theme/           (Material theming)
│   │   │   ├── data/
│   │   │   │   ├── repository/      (Data repositories)
│   │   │   │   ├── model/           (Data models)
│   │   │   │   └── source/          (Firebase, API clients)
│   │   │   ├── domain/
│   │   │   │   ├── usecase/         (Business logic)
│   │   │   │   └── model/           (Domain models)
│   │   │   └── di/                  (Dependency injection)
│   │   └── res/                     (Resources)
│   └── test/                        (Tests)
└── build.gradle.kts
```

## Dependencies (build.gradle.kts)

```kotlin
dependencies {
    // Jetpack Compose
    implementation("androidx.compose.ui:ui:1.5.4")
    implementation("androidx.compose.material3:material3:1.1.2")
    implementation("androidx.compose.ui:ui-tooling-preview:1.5.4")

    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-functions-ktx")

    // Stripe
    implementation("com.stripe:stripe-android:20.37.0")

    // Google Sign-In
    implementation("com.google.android.gms:play-services-auth:20.7.0")

    // Image Loading
    implementation("io.coil-kt:coil-compose:2.5.0")

    // QR Code
    implementation("com.google.mlkit:barcode-scanning:17.2.0")

    // Widgets
    implementation("androidx.glance:glance-appwidget:1.0.0")

    // Location
    implementation("com.google.android.gms:play-services-location:21.0.1")

    // Architecture Components
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    implementation("androidx.navigation:navigation-compose:2.7.6")

    // Dependency Injection
    implementation("com.google.dagger:hilt-android:2.48")
    kapt("com.google.dagger:hilt-compiler:2.48")
}
```

## Platform Differences to Consider

### 1. Navigation
- iOS: NavigationStack, NavigationLink
- Android: Jetpack Navigation Compose with NavHost

### 2. State Management
- iOS: @State, @StateObject, @ObservedObject
- Android: remember, MutableState, StateFlow, ViewModel

### 3. Permissions
- iOS: Info.plist entries, runtime prompts
- Android: Manifest + runtime permissions (more granular)

### 4. Design Guidelines
- iOS: Human Interface Guidelines
- Android: Material Design 3

### 5. Back Button Behavior
- Android has system back button - needs proper handling
- Use predictive back gestures (Android 13+)

## Challenges & Considerations

### 1. Burner Mode Lock Screen
- Android restricts background overlays
- May need to be implemented as:
  - Device Admin app with kiosk mode
  - Accessibility service (user must enable)
  - Optional feature depending on permissions
- **User education required** - more complex setup than iOS

### 2. App Distribution
- Google Play Store approval process
- Different review guidelines than Apple
- Consider beta testing via Google Play Console

### 3. Device Fragmentation
- Test on multiple screen sizes and Android versions
- Minimum SDK version recommendation: API 24 (Android 7.0)
- Target latest stable API

### 4. Testing on Physical Devices
- Payment features require physical device testing
- Camera/QR scanning needs real device
- Location features need GPS-enabled device

## Resources
- [Android Developer Documentation](https://developer.android.com)
- [Jetpack Compose](https://developer.android.com/jetpack/compose)
- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)
- [Stripe Android SDK](https://stripe.com/docs/mobile/android)
- [Material Design 3](https://m3.material.io)
- [Kotlin Documentation](https://kotlinlang.org/docs/home.html)

## Timeline Estimate
- **Minimum Viable Product (MVP)**: 12-16 weeks
- **Feature Complete**: 20-24 weeks
- **Production Ready**: 24-28 weeks

*Timeline assumes 1-2 dedicated Android developers familiar with Kotlin and Jetpack Compose.*

## Next Steps
1. Set up Android development environment (Android Studio)
2. Create Firebase Android app in Firebase Console
3. Set up Stripe Android test account
4. Create initial project structure
5. Implement authentication flow as first feature
6. Iterate with regular testing and feedback
