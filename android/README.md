# Burner Android App

Android version of the Burner event ticketing app, built with Jetpack Compose and Kotlin.

## Architecture

- **UI Framework**: Jetpack Compose with Material 3
- **Language**: Kotlin
- **Architecture Pattern**: MVVM with StateFlow
- **Dependency Injection**: Hilt
- **Navigation**: Jetpack Compose Navigation
- **Backend**: Firebase (Firestore, Authentication)
- **Payments**: Stripe

## Features

### Implemented
- **Authentication**: Email/password and Google Sign-In
- **Onboarding**: Location setup, genre selection, notification permissions
- **Explore Tab**: Featured events, this week's events, nearby events
- **Search Tab**: Full-text search with sorting by date, price, and proximity
- **Bookmarks Tab**: Save events for later
- **Tickets Tab**: View purchased tickets with QR codes
- **Event Details**: Full event information with ticket purchasing
- **Ticket Purchase**: Stripe integration for secure payments
- **Settings**: Account, payment methods, notifications, support

### Placeholder/Stub Features
- **Burner Mode**: Offline/focus mode during events (iOS-specific Screen Time features)
- **NFC Unlock**: Near-field communication unlock (stub)
- **Live Activities**: iOS-only feature (not applicable to Android)

## Project Structure

```
app/src/main/java/com/burner/app/
├── BurnerApplication.kt          # Application class
├── MainActivity.kt               # Main activity
├── data/
│   ├── models/                   # Data models (Event, Ticket, etc.)
│   └── repository/               # Data repositories
├── di/                           # Hilt dependency injection
├── navigation/                   # Navigation routes and hosts
├── services/                     # Business logic services
│   ├── AuthService.kt
│   ├── PaymentService.kt
│   └── BurnerFirebaseMessagingService.kt
└── ui/
    ├── components/               # Reusable UI components
    ├── screens/                  # Screen composables
    │   ├── auth/
    │   ├── bookmarks/
    │   ├── explore/
    │   ├── onboarding/
    │   ├── search/
    │   ├── settings/
    │   └── tickets/
    └── theme/                    # Theme, colors, typography
```

## Setup

### Prerequisites
- Android Studio Hedgehog (2023.1.1) or later
- JDK 17
- Android SDK 34

### Firebase Configuration
1. Create a Firebase project at https://console.firebase.google.com
2. Add an Android app with package name `com.burner.app`
3. Download `google-services.json` and place it in `app/` directory
4. Enable Authentication (Email/Password and Google)
5. Create Firestore database

### Stripe Configuration
1. Get your publishable key from Stripe dashboard
2. Update the key in `BurnerApplication.kt`
3. Set up Cloud Functions for payment intent creation

### Building
```bash
# Debug build
./gradlew assembleDebug

# Release build
./gradlew assembleRelease
```

## Dependencies

- Jetpack Compose BOM 2023.10.01
- Hilt 2.48
- Firebase BOM 32.7.0
- Stripe Android 20.35.1
- Coil 2.5.0
- Navigation Compose 2.7.5

## Theme

The app uses a dark theme to match the iOS version:
- Background: Pure black (#000000)
- Primary: White (#FFFFFF)
- Typography: System default (Roboto, similar to Helvetica on iOS)

## Contributing

1. Follow Kotlin coding conventions
2. Use Compose best practices
3. Write meaningful commit messages
4. Test on multiple device sizes

## License

Proprietary - All rights reserved
