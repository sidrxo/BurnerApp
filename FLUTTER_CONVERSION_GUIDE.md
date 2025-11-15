# Flutter Conversion Guide for Burner App

## Overview

This guide provides a step-by-step technical roadmap for converting your native iOS SwiftUI app to Flutter, enabling cross-platform deployment to both iOS and Android.

**Current Stack:** SwiftUI + Firebase
**Target Stack:** Flutter + Firebase
**Expected Code Reuse:** 75-80%
**Timeline:** 12-16 weeks

---

## Table of Contents

1. [Prerequisites & Setup](#prerequisites--setup)
2. [Project Structure](#project-structure)
3. [Dependencies & Packages](#dependencies--packages)
4. [Architecture Mapping](#architecture-mapping)
5. [Data Models](#data-models)
6. [Firebase Integration](#firebase-integration)
7. [Authentication](#authentication)
8. [UI Components](#ui-components)
9. [State Management](#state-management)
10. [Feature-by-Feature Conversion](#feature-by-feature-conversion)
11. [Platform-Specific Features](#platform-specific-features)
12. [Testing Strategy](#testing-strategy)
13. [Deployment](#deployment)

---

## Prerequisites & Setup

### 1. Install Flutter

```bash
# macOS
brew install flutter

# Verify installation
flutter doctor

# Enable iOS and Android platforms
flutter config --enable-ios
flutter config --enable-android
```

### 2. IDE Setup

**Recommended:** VS Code or Android Studio

```bash
# VS Code extensions
code --install-extension Dart-Code.dart-code
code --install-extension Dart-Code.flutter
```

### 3. Create Flutter Project

```bash
cd /path/to/projects
flutter create burner_flutter --org com.burner

cd burner_flutter

# Test it works
flutter run
```

### 4. Project Configuration

**pubspec.yaml** (initial setup):
```yaml
name: burner_flutter
description: Event ticketing platform with Burner Mode
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_riverpod: ^2.4.9

  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  firebase_analytics: ^10.7.4

  # UI & Navigation
  go_router: ^12.1.3
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0

  # Payments
  flutter_stripe: ^10.1.1

  # Utilities
  intl: ^0.18.1
  uuid: ^4.2.2
  qr_flutter: ^4.1.0
  mobile_scanner: ^3.5.5
  geolocator: ^10.1.0
  url_launcher: ^6.2.2

  # Google Sign-In
  google_sign_in: ^6.1.6

  # Platform-specific
  device_info_plus: ^9.1.1
  package_info_plus: ^5.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
```

---

## Project Structure

### Recommended Flutter Architecture

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # Root widget with routing
├── core/
│   ├── config/
│   │   ├── firebase_config.dart       # Firebase initialization
│   │   ├── stripe_config.dart         # Stripe setup
│   │   └── app_constants.dart         # Constants
│   ├── models/
│   │   ├── event.dart                 # Event model
│   │   ├── ticket.dart                # Ticket model
│   │   ├── user_profile.dart          # User model
│   │   └── payment_intent.dart        # Payment models
│   ├── services/
│   │   ├── firebase/
│   │   │   ├── auth_service.dart      # Authentication
│   │   │   ├── firestore_service.dart # Database operations
│   │   │   └── storage_service.dart   # File uploads
│   │   ├── payment_service.dart       # Stripe integration
│   │   └── location_service.dart      # Geolocation
│   ├── repositories/
│   │   ├── event_repository.dart      # Event data access
│   │   ├── ticket_repository.dart     # Ticket data access
│   │   └── user_repository.dart       # User data access
│   ├── providers/
│   │   ├── auth_provider.dart         # Auth state
│   │   ├── event_provider.dart        # Event state
│   │   └── ticket_provider.dart       # Ticket state
│   └── utils/
│       ├── extensions.dart            # Dart extensions
│       ├── validators.dart            # Input validation
│       └── formatters.dart            # Date/currency formatting
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── passwordless_screen.dart
│   │   └── widgets/
│   │       ├── auth_button.dart
│   │       └── social_login_buttons.dart
│   ├── explore/
│   │   ├── screens/
│   │   │   ├── explore_screen.dart
│   │   │   └── event_detail_screen.dart
│   │   └── widgets/
│   │       ├── event_card.dart
│   │       ├── featured_events.dart
│   │       └── nearby_events.dart
│   ├── search/
│   │   ├── screens/
│   │   │   └── search_screen.dart
│   │   └── widgets/
│   │       └── search_bar.dart
│   ├── tickets/
│   │   ├── screens/
│   │   │   ├── tickets_screen.dart
│   │   │   ├── ticket_detail_screen.dart
│   │   │   └── scanner_screen.dart
│   │   └── widgets/
│   │       ├── ticket_card.dart
│   │       ├── qr_code_display.dart
│   │       └── purchase_sheet.dart
│   ├── burner_mode/
│   │   ├── screens/
│   │   │   └── burner_mode_screen.dart
│   │   ├── services/
│   │   │   ├── burner_mode_ios.dart
│   │   │   └── burner_mode_android.dart
│   │   └── widgets/
│   │       └── app_blocker.dart
│   └── settings/
│       ├── screens/
│       │   ├── settings_screen.dart
│       │   └── profile_screen.dart
│       └── widgets/
│           └── settings_tile.dart
├── shared/
│   └── widgets/
│       ├── primary_button.dart
│       ├── loading_indicator.dart
│       ├── error_view.dart
│       └── bottom_nav_bar.dart
└── platform/
    ├── ios/
    │   └── live_activity_handler.dart
    └── android/
        └── notification_handler.dart
```

### Mapping from iOS Structure

| iOS (SwiftUI) | Flutter | Notes |
|---------------|---------|-------|
| `BurnerApp.swift` | `main.dart` | App entry point |
| `AppState.swift` | `providers/` | State management |
| `Models.swift` | `core/models/` | Data models |
| `Components/` | `shared/widgets/` | Reusable UI |
| `Extensions/Services/` | `core/services/` | Business logic |
| `Extensions/Repositories/` | `core/repositories/` | Data access |
| Views (`.swift` files) | `features/*/screens/` | Screens |
| `Info.plist` | `AndroidManifest.xml` + iOS config | Platform configs |

---

## Dependencies & Packages

### iOS → Flutter Package Mapping

| iOS Dependency | Flutter Package | Purpose |
|----------------|-----------------|---------|
| Firebase iOS SDK | `firebase_core`, `firebase_auth`, etc. | Firebase services |
| Kingfisher | `cached_network_image` | Image caching |
| Google Sign-In SDK | `google_sign_in` | Google authentication |
| Stripe iOS | `flutter_stripe` | Payments |
| CoreLocation | `geolocator` | Location services |
| PassKit (Apple Pay) | `flutter_stripe` + platform channels | Payment processing |
| ActivityKit | Platform channels | Live Activities (iOS only) |
| FamilyControls | Platform channels | Screen Time (iOS only) |

### Key Flutter Packages Explained

**State Management: Riverpod**
```dart
// Why Riverpod?
// - Type-safe (compile-time errors)
// - Testable
// - No BuildContext needed
// - Similar to SwiftUI's @StateObject/@EnvironmentObject
```

**Navigation: GoRouter**
```dart
// Why GoRouter?
// - Declarative routing (like SwiftUI NavigationStack)
// - Deep linking support
// - Type-safe navigation
```

**Firebase: FlutterFire**
```dart
// Official Firebase plugins from Google
// Nearly identical API to iOS SDK
```

---

## Architecture Mapping

### SwiftUI vs Flutter Concepts

| SwiftUI | Flutter | Example |
|---------|---------|---------|
| `View` | `Widget` | UI building blocks |
| `@State` | `StatefulWidget` + `setState()` | Local state |
| `@StateObject` | `ChangeNotifier` / `Riverpod Provider` | Shared state |
| `@EnvironmentObject` | `Provider` / `Riverpod` | Dependency injection |
| `@Published` | `notifyListeners()` | State updates |
| `ObservableObject` | `ChangeNotifier` | Observable pattern |
| `NavigationStack` | `GoRouter` / `Navigator 2.0` | Navigation |
| `.sheet()` | `showModalBottomSheet()` | Modal presentation |
| `.alert()` | `showDialog()` | Alerts |
| `AsyncImage` | `CachedNetworkImage` | Remote images |
| `.task()` | `FutureBuilder` / `initState()` | Async operations |

### State Management Pattern

**Your current iOS approach:**
```swift
// AppState.swift
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
}

// BurnerApp.swift
@StateObject private var appState = AppState()
```

**Flutter equivalent with Riverpod:**
```dart
// core/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isAuthenticated;
  final User? currentUser;

  AuthState({
    required this.isAuthenticated,
    this.currentUser,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? currentUser,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isAuthenticated: false));

  void setUser(User? user) {
    state = state.copyWith(
      isAuthenticated: user != null,
      currentUser: user,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
```

**Using in widgets:**
```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return LoginScreen();
    }

    return Text('Hello ${authState.currentUser?.name}');
  }
}
```

---

## Data Models

### Converting Swift Models to Dart

**iOS Model (Swift):**
```swift
// Models.swift
struct Event: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
    let location: GeoPoint
    let venueName: String
    let imageUrl: String?
    let price: Decimal
    let tags: [String]
    let featured: Bool
}
```

**Flutter Model (Dart):**
```dart
// core/models/event.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final GeoPoint location;
  final String venueName;
  final String? imageUrl;
  final double price;
  final List<String> tags;
  final bool featured;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.venueName,
    this.imageUrl,
    required this.price,
    required this.tags,
    required this.featured,
  });

  // From Firestore
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint,
      venueName: data['venueName'] ?? '',
      imageUrl: data['imageUrl'],
      price: (data['price'] as num).toDouble(),
      tags: List<String>.from(data['tags'] ?? []),
      featured: data['featured'] ?? false,
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'venueName': venueName,
      'imageUrl': imageUrl,
      'price': price,
      'tags': tags,
      'featured': featured,
    };
  }

  // JSON serialization (for API calls)
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      location: GeoPoint(json['latitude'], json['longitude']),
      venueName: json['venueName'],
      imageUrl: json['imageUrl'],
      price: json['price'].toDouble(),
      tags: List<String>.from(json['tags']),
      featured: json['featured'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'latitude': location.latitude,
      'longitude': location.longitude,
      'venueName': venueName,
      'imageUrl': imageUrl,
      'price': price,
      'tags': tags,
      'featured': featured,
    };
  }

  // Copy with (for state updates)
  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    GeoPoint? location,
    String? venueName,
    String? imageUrl,
    double? price,
    List<String>? tags,
    bool? featured,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      venueName: venueName ?? this.venueName,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      tags: tags ?? this.tags,
      featured: featured ?? this.featured,
    );
  }
}
```

**Key Differences:**
- Dart uses `class` instead of `struct`
- `DateTime` instead of `Date`
- `double` instead of `Decimal` (for prices, consider using a Money package)
- Explicit `fromFirestore()` and `toFirestore()` methods
- `copyWith()` for immutable updates

---

## Firebase Integration

### 1. Firebase Setup

**iOS (current):**
```swift
// BurnerApp.swift
import FirebaseCore

@main
struct BurnerApp: App {
    init() {
        FirebaseApp.configure()
    }
}
```

**Flutter equivalent:**
```dart
// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generated file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: BurnerApp()));
}
```

**Generate Firebase config:**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (interactive)
flutterfire configure
```

### 2. Firestore Operations

**iOS (Swift):**
```swift
// EventRepository.swift
func fetchFeaturedEvents() async throws -> [Event] {
    let snapshot = try await db.collection("events")
        .whereField("featured", isEqualTo: true)
        .order(by: "startDate")
        .getDocuments()

    return snapshot.documents.compactMap { doc in
        try? doc.data(as: Event.self)
    }
}
```

**Flutter (Dart):**
```dart
// core/repositories/event_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Event>> fetchFeaturedEvents() async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('featured', isEqualTo: true)
          .orderBy('startDate')
          .get();

      return snapshot.docs
          .map((doc) => Event.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch featured events: $e');
    }
  }

  // Streaming events (real-time updates)
  Stream<List<Event>> featuredEventsStream() {
    return _firestore
        .collection('events')
        .where('featured', isEqualTo: true)
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  // Geolocation query (nearby events)
  Future<List<Event>> fetchNearbyEvents({
    required double latitude,
    required double longitude,
    double radiusInKm = 50.0,
  }) async {
    // Note: Firestore doesn't have native geo queries
    // Use geoflutterfire2 package or filter client-side

    // Simple implementation: fetch all and filter
    final snapshot = await _firestore.collection('events').get();

    return snapshot.docs
        .map((doc) => Event.fromFirestore(doc))
        .where((event) {
          final distance = _calculateDistance(
            latitude,
            longitude,
            event.location.latitude,
            event.location.longitude,
          );
          return distance <= radiusInKm;
        })
        .toList();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
```

**Riverpod Provider:**
```dart
// core/providers/event_provider.dart
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

final featuredEventsProvider = FutureProvider<List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.fetchFeaturedEvents();
});

// Stream provider for real-time updates
final featuredEventsStreamProvider = StreamProvider<List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.featuredEventsStream();
});
```

---

## Authentication

### Firebase Auth Implementation

**iOS (Swift):**
```swift
// AuthenticationService.swift
func signInWithEmail(email: String, password: String) async throws -> User {
    let result = try await Auth.auth().signIn(withEmail: email, password: password)
    return result.user
}
```

**Flutter (Dart):**
```dart
// core/services/firebase/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email/Password Sign In
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Email/Password Sign Up
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google Sign In
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in aborted');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Passwordless (Email Link)
  Future<void> sendSignInLink(String email) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://manageburner.online/finishSignIn',
        handleCodeInApp: true,
        iOSBundleId: 'com.burner.app',
        androidPackageName: 'com.burner.app',
      );

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    try {
      return await _auth.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Error handling
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
```

**Auth Provider:**
```dart
// core/providers/auth_provider.dart
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});
```

**Login Screen Example:**
```dart
// features/auth/screens/login_screen.dart
class LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Navigation handled by auth state listener
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## UI Components

### SwiftUI to Flutter Widget Conversion

**Example: Event Card**

**iOS (SwiftUI):**
```swift
// EventCard.swift
struct EventCard: View {
    let event: Event

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: event.imageUrl ?? "")) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(height: 200)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)

                Text(event.venueName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("£\(event.price, specifier: "%.2f")")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
```

**Flutter equivalent:**
```dart
// features/explore/widgets/event_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCard({
    Key? key,
    required this.event,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: event.imageUrl ?? '',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),

            // Event details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.venueName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '£${event.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Common Widget Mappings

| SwiftUI | Flutter | Example |
|---------|---------|---------|
| `VStack` | `Column` | Vertical layout |
| `HStack` | `Row` | Horizontal layout |
| `ZStack` | `Stack` | Overlapping widgets |
| `List` | `ListView` | Scrollable list |
| `ScrollView` | `SingleChildScrollView` | Scrollable content |
| `Text` | `Text` | Text display |
| `Button` | `ElevatedButton` / `TextButton` | Buttons |
| `TextField` | `TextField` | Text input |
| `Image` | `Image` | Static images |
| `AsyncImage` | `CachedNetworkImage` | Remote images |
| `Spacer()` | `Spacer()` | Flexible space |
| `Divider()` | `Divider()` | Horizontal line |
| `.padding()` | `Padding(...)` | Add padding |
| `.background()` | `Container(color: ...)` | Background color |
| `.cornerRadius()` | `BorderRadius.circular()` | Rounded corners |
| `.shadow()` | `BoxShadow` | Drop shadow |
| `.sheet()` | `showModalBottomSheet()` | Modal |
| `.alert()` | `showDialog()` | Alert dialog |
| `NavigationLink` | `Navigator.push()` | Navigation |
| `.onAppear()` | `initState()` | Lifecycle |

---

## State Management

### Repository + Provider Pattern

**Event Provider Example:**

```dart
// core/providers/event_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

// Featured events
final featuredEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.fetchFeaturedEvents();
});

// Nearby events (with location)
final nearbyEventsProvider = FutureProvider.family<List<Event>, Location>(
  (ref, location) async {
    final repository = ref.watch(eventRepositoryProvider);
    return repository.fetchNearbyEvents(
      latitude: location.latitude,
      longitude: location.longitude,
    );
  },
);

// Search events
final searchEventsProvider = FutureProvider.family<List<Event>, String>(
  (ref, query) async {
    final repository = ref.watch(eventRepositoryProvider);
    return repository.searchEvents(query);
  },
);

// Bookmarked events (stateful)
class BookmarksNotifier extends StateNotifier<Set<String>> {
  BookmarksNotifier() : super({});

  void toggleBookmark(String eventId) {
    if (state.contains(eventId)) {
      state = {...state}..remove(eventId);
    } else {
      state = {...state, eventId};
    }
  }

  bool isBookmarked(String eventId) => state.contains(eventId);
}

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, Set<String>>(
  (ref) => BookmarksNotifier(),
);
```

**Using in UI:**

```dart
class ExploreScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredEventsAsync = ref.watch(featuredEventsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: featuredEventsAsync.when(
        data: (events) => ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return EventCard(
              event: event,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(event: event),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

---

## Feature-by-Feature Conversion

### 1. Explore Tab

**Flutter Implementation:**

```dart
// features/explore/screens/explore_screen.dart
class ExploreScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  @override
  Widget build(BuildContext context) {
    final featuredEvents = ref.watch(featuredEventsProvider);
    final nearbyEvents = ref.watch(nearbyEventsProvider(currentLocation));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featuredEventsProvider);
          ref.invalidate(nearbyEventsProvider);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Featured section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Featured Events',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              featuredEvents.when(
                data: (events) => SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 250,
                          child: EventCard(event: events[index]),
                        ),
                      );
                    },
                  ),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Text('Error: $err'),
              ),

              const SizedBox(height: 24),

              // Nearby section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Nearby Events',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              nearbyEvents.when(
                data: (events) => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: EventCard(event: events[index]),
                    );
                  },
                ),
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Text('Error: $err'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 2. Ticket Purchasing with Stripe

```dart
// core/services/payment_service.dart
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  Future<void> initializePayment({
    required Event event,
    required int quantity,
  }) async {
    try {
      // 1. Create payment intent on backend
      final paymentIntent = await _createPaymentIntent(
        amount: (event.price * quantity * 100).toInt(), // pence
        currency: 'gbp',
      );

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Burner Tickets',
          paymentIntentClientSecret: paymentIntent['client_secret'],
          customerEphemeralKeySecret: paymentIntent['ephemeral_key'],
          customerId: paymentIntent['customer'],
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'GB',
          ),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'GB',
            testEnv: true,
          ),
          style: ThemeMode.system,
        ),
      );

      // 3. Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Payment successful - create tickets
      await _createTickets(event, quantity);

    } on StripeException catch (e) {
      throw Exception('Payment failed: ${e.error.localizedMessage}');
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent({
    required int amount,
    required String currency,
  }) async {
    // Call your Firebase Cloud Function
    final response = await http.post(
      Uri.parse('https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/createPaymentIntent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<void> _createTickets(Event event, int quantity) async {
    // Create tickets in Firestore
    final batch = FirebaseFirestore.instance.batch();

    for (int i = 0; i < quantity; i++) {
      final ticketRef = FirebaseFirestore.instance
          .collection('tickets')
          .doc();

      batch.set(ticketRef, {
        'eventId': event.id,
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'qrCode': ticketRef.id,
        'purchaseDate': FieldValue.serverTimestamp(),
        'status': 'active',
      });
    }

    await batch.commit();
  }
}
```

**Purchase button in UI:**
```dart
ElevatedButton(
  onPressed: () async {
    try {
      final paymentService = ref.read(paymentServiceProvider);
      await paymentService.initializePayment(
        event: event,
        quantity: 1,
      );

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket purchased!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  },
  child: const Text('Buy Ticket'),
)
```

### 3. QR Code Ticket Display

```dart
// features/tickets/widgets/qr_code_display.dart
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeDisplay extends StatelessWidget {
  final String ticketId;

  const QRCodeDisplay({required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: QrImageView(
        data: ticketId,
        version: QrVersions.auto,
        size: 200.0,
        backgroundColor: Colors.white,
      ),
    );
  }
}
```

### 4. QR Scanner

```dart
// features/tickets/screens/scanner_screen.dart
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ticket'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.off ? Icons.flash_off : Icons.flash_on,
                );
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;
            if (code != null) {
              _handleScannedTicket(code);
              Navigator.pop(context);
            }
          }
        },
      ),
    );
  }

  Future<void> _handleScannedTicket(String ticketId) async {
    // Verify and redeem ticket
    final ticketDoc = await FirebaseFirestore.instance
        .collection('tickets')
        .doc(ticketId)
        .get();

    if (!ticketDoc.exists) {
      _showError('Invalid ticket');
      return;
    }

    final data = ticketDoc.data()!;
    if (data['status'] == 'redeemed') {
      _showError('Ticket already used');
      return;
    }

    // Mark as redeemed
    await ticketDoc.reference.update({
      'status': 'redeemed',
      'redeemedAt': FieldValue.serverTimestamp(),
    });

    _showSuccess('Ticket validated successfully');
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## Platform-Specific Features

### 1. Live Activities (iOS) vs Notifications (Android)

**iOS Live Activity:**
```dart
// platform/ios/live_activity_handler.dart
import 'package:flutter/services.dart';

class LiveActivityHandler {
  static const platform = MethodChannel('com.burner.app/live_activity');

  Future<void> startActivity({
    required String eventId,
    required String eventName,
    required DateTime endTime,
  }) async {
    if (!Platform.isIOS) return;

    try {
      await platform.invokeMethod('startActivity', {
        'eventId': eventId,
        'eventName': eventName,
        'endTime': endTime.millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Failed to start Live Activity: $e');
    }
  }

  Future<void> updateActivity({
    required String eventId,
    required int remainingMinutes,
  }) async {
    if (!Platform.isIOS) return;

    try {
      await platform.invokeMethod('updateActivity', {
        'eventId': eventId,
        'remainingMinutes': remainingMinutes,
      });
    } catch (e) {
      print('Failed to update Live Activity: $e');
    }
  }

  Future<void> endActivity(String eventId) async {
    if (!Platform.isIOS) return;

    try {
      await platform.invokeMethod('endActivity', {'eventId': eventId});
    } catch (e) {
      print('Failed to end Live Activity: $e');
    }
  }
}
```

**Android Ongoing Notification:**
```dart
// platform/android/notification_handler.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHandler {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  Future<void> showEventNotification({
    required String eventName,
    required DateTime endTime,
  }) async {
    if (!Platform.isAndroid) return;

    final remainingTime = endTime.difference(DateTime.now());
    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes % 60;

    await _notifications.show(
      0,
      eventName,
      '$hours:${minutes.toString().padLeft(2, '0')} remaining',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'event_channel',
          'Event Notifications',
          channelDescription: 'Ongoing event notifications',
          importance: Importance.high,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
          showProgress: true,
          progress: _calculateProgress(endTime),
          maxProgress: 100,
        ),
      ),
    );
  }

  int _calculateProgress(DateTime endTime) {
    // Calculate percentage based on event duration
    final now = DateTime.now();
    final totalDuration = endTime.difference(startTime).inMinutes;
    final elapsed = now.difference(startTime).inMinutes;
    return ((elapsed / totalDuration) * 100).toInt();
  }
}
```

### 2. Burner Mode

**iOS Screen Time API (platform channel):**
```dart
// features/burner_mode/services/burner_mode_ios.dart
import 'package:flutter/services.dart';

class BurnerModeIOS {
  static const platform = MethodChannel('com.burner.app/burner_mode');

  Future<bool> requestAuthorization() async {
    try {
      return await platform.invokeMethod('requestAuthorization');
    } catch (e) {
      print('Failed to request authorization: $e');
      return false;
    }
  }

  Future<void> blockApps(List<String> appBundleIds) async {
    try {
      await platform.invokeMethod('blockApps', {'apps': appBundleIds});
    } catch (e) {
      print('Failed to block apps: $e');
    }
  }

  Future<void> unblockApps() async {
    try {
      await platform.invokeMethod('unblockApps');
    } catch (e) {
      print('Failed to unblock apps: $e');
    }
  }
}
```

**Android Focus Mode (overlay approach):**
```dart
// features/burner_mode/services/burner_mode_android.dart
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class BurnerModeAndroid {
  Future<bool> requestPermissions() async {
    // Request usage stats permission
    bool granted = await UsageStats.checkUsagePermission() ?? false;
    if (!granted) {
      UsageStats.grantUsagePermission();
    }

    // Request overlay permission
    bool overlayGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!overlayGranted) {
      await FlutterOverlayWindow.requestPermission();
    }

    return granted && overlayGranted;
  }

  Future<void> startMonitoring(List<String> blockedApps) async {
    // Start background service to monitor app usage
    UsageStats.queryUsageStats(
      DateTime.now().subtract(const Duration(seconds: 1)),
      DateTime.now(),
    ).then((stats) {
      for (final stat in stats) {
        if (blockedApps.contains(stat.packageName)) {
          _showBlockingOverlay();
        }
      }
    });
  }

  Future<void> _showBlockingOverlay() async {
    await FlutterOverlayWindow.showOverlay(
      height: WindowSize.fullScreen,
      width: WindowSize.fullScreen,
      alignment: OverlayAlignment.center,
    );
  }
}
```

**Unified Burner Mode Service:**
```dart
// features/burner_mode/services/burner_mode_service.dart
class BurnerModeService {
  final BurnerModeIOS? _ios = Platform.isIOS ? BurnerModeIOS() : null;
  final BurnerModeAndroid? _android = Platform.isAndroid ? BurnerModeAndroid() : null;

  Future<bool> enableBurnerMode(Event event) async {
    if (Platform.isIOS) {
      final authorized = await _ios!.requestAuthorization();
      if (!authorized) return false;

      await _ios!.blockApps(event.blockedApps);
      return true;
    } else {
      final granted = await _android!.requestPermissions();
      if (!granted) return false;

      await _android!.startMonitoring(event.blockedApps);
      return true;
    }
  }

  Future<void> disableBurnerMode() async {
    if (Platform.isIOS) {
      await _ios!.unblockApps();
    } else {
      await _android!.stopMonitoring();
    }
  }
}
```

---

## Testing Strategy

### Unit Tests

```dart
// test/repositories/event_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('EventRepository', () {
    late EventRepository repository;
    late MockFirebaseFirestore mockFirestore;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      repository = EventRepository(firestore: mockFirestore);
    });

    test('fetchFeaturedEvents returns list of events', () async {
      // Arrange
      final mockSnapshot = MockQuerySnapshot();
      when(mockFirestore.collection('events')
          .where('featured', isEqualTo: true)
          .get())
          .thenAnswer((_) async => mockSnapshot);

      // Act
      final events = await repository.fetchFeaturedEvents();

      // Assert
      expect(events, isA<List<Event>>());
    });
  });
}
```

### Widget Tests

```dart
// test/widgets/event_card_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EventCard displays event information', (tester) async {
    final event = Event(
      id: '1',
      title: 'Test Event',
      venueName: 'Test Venue',
      price: 10.0,
      // ... other fields
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventCard(event: event),
        ),
      ),
    );

    expect(find.text('Test Event'), findsOneWidget);
    expect(find.text('Test Venue'), findsOneWidget);
    expect(find.text('£10.00'), findsOneWidget);
  });
}
```

---

## Deployment

### iOS Configuration

**ios/Runner/Info.plist additions:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>burner</string>
        </array>
    </dict>
</array>

<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby events</string>

<key>NSCameraUsageDescription</key>
<string>We need camera access to scan tickets</string>
```

### Android Configuration

**android/app/src/main/AndroidManifest.xml:**
```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.CAMERA"/>

    <application>
        <!-- Deep linking -->
        <intent-filter android:autoVerify="true">
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data
                android:scheme="https"
                android:host="manageburner.online" />
        </intent-filter>

        <!-- Custom URL scheme -->
        <intent-filter>
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.DEFAULT" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="burner" />
        </intent-filter>
    </application>
</manifest>
```

### Build & Release

```bash
# iOS
flutter build ios --release
# Then use Xcode to archive and upload to App Store

# Android
flutter build appbundle --release
# Upload to Play Console
```

---

## Migration Timeline

### Week 1-2: Setup & Infrastructure
- ✅ Flutter project setup
- ✅ Firebase integration
- ✅ Project structure
- ✅ Dependencies configuration
- ✅ Basic navigation

### Week 3-4: Data Layer
- ✅ Models conversion
- ✅ Repositories
- ✅ Firebase services
- ✅ State management setup

### Week 5-6: Authentication
- ✅ Login/signup screens
- ✅ Google Sign-In
- ✅ Passwordless auth
- ✅ Auth state management

### Week 7-9: Core Features
- ✅ Explore tab
- ✅ Search functionality
- ✅ Event details
- ✅ Bookmarks

### Week 10-11: Ticketing
- ✅ Stripe integration
- ✅ Payment flow
- ✅ Ticket display
- ✅ QR codes
- ✅ Scanner

### Week 12-13: Burner Mode
- ✅ iOS Screen Time integration
- ✅ Android alternative
- ✅ Permissions handling
- ✅ Background monitoring

### Week 14-15: Platform Features
- ✅ Live Activities (iOS)
- ✅ Notifications (Android)
- ✅ Deep linking
- ✅ Location services

### Week 16: Polish & Testing
- ✅ UI refinement
- ✅ Bug fixes
- ✅ Performance optimization
- ✅ Beta testing

---

## Key Considerations

### 1. Burner Mode Limitations on Android
- Cannot force-block apps like iOS Screen Time API
- Requires user cooperation
- Consider UX adjustments:
  - Gamification
  - Persistent reminders
  - Post-event reports
  - Accessibility Service (requires permission)

### 2. Payment Processing
- Stripe Payment Sheet works on both platforms
- Apple Pay (iOS) and Google Pay (Android) supported
- Test thoroughly in both environments

### 3. Firebase Costs
- Same backend serves both platforms
- Monitor usage carefully
- Implement pagination for large lists
- Use Firebase emulator for development

### 4. Performance
- Use `const` constructors where possible
- Implement pagination/infinite scroll
- Cache images with `cached_network_image`
- Profile with DevTools before release

---

## Resources

### Official Documentation
- [Flutter Documentation](https://docs.flutter.dev)
- [FlutterFire](https://firebase.flutter.dev)
- [Riverpod](https://riverpod.dev)
- [GoRouter](https://pub.dev/packages/go_router)

### Packages
- [pub.dev](https://pub.dev) - Package repository
- [flutter_stripe](https://pub.dev/packages/flutter_stripe)
- [cached_network_image](https://pub.dev/packages/cached_network_image)
- [qr_flutter](https://pub.dev/packages/qr_flutter)

### Community
- [Flutter Discord](https://discord.gg/flutter)
- [r/FlutterDev](https://reddit.com/r/FlutterDev)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

---

## Next Steps

1. **Set up development environment**
   - Install Flutter
   - Configure IDEs
   - Set up Firebase project

2. **Create project structure**
   - Initialize Flutter project
   - Configure dependencies
   - Set up folder structure

3. **Start with authentication**
   - Implement login/signup
   - Test Firebase integration
   - Verify state management

4. **Build incrementally**
   - One feature at a time
   - Test on both iOS and Android
   - Iterate based on feedback

5. **Deploy beta**
   - TestFlight (iOS)
   - Internal Testing (Android)
   - Gather user feedback

Good luck with your Flutter conversion! 🚀
