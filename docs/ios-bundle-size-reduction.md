# iOS App Bundle Size Reduction Opportunities

**Generated:** 2025-11-12
**App:** Burner (com.gas.Burner)
**Current iOS Target:** 18.0+

---

## Executive Summary

This document outlines opportunities to reduce the iOS app bundle and install size for the Burner app. Recommendations are organized by impact level, from quick wins to strategic optimizations.

**Estimated Total Savings: 15-40% bundle size reduction**

---

## 🔴 High Impact Opportunities

### 1. Firebase SDK Optimization (Estimated savings: 20-30MB)

**Current State:**
- Using Firebase v12.5.0 with Auth, Core, Firestore, and Functions
- Firebase is one of the largest dependencies in iOS apps

**Recommendations:**

#### Option A: Use Firebase Dynamic Links (Recommended)
```swift
// Instead of:
import Firebase
import FirebaseAuth
import FirebaseFirestore

// Use dynamic frameworks and only import what you need in each file
```

**Benefits:**
- Reduces embedded framework duplication
- App Store thinning optimizes downloads per device
- Estimated savings: 10-15MB

#### Option B: Evaluate Firebase Necessity
Review if all Firebase modules are essential:
- **Firestore**: Can this be replaced with REST API calls to reduce client-side SDK?
- **Firebase Functions**: Consider direct HTTPS calls instead of SDK
- **Firebase Auth**: Could use lighter alternatives if only using email/password

**Action Items:**
- [ ] Audit actual Firebase feature usage across the app
- [ ] Consider migrating to Firebase REST APIs for some features
- [ ] Enable bitcode if supported (helps with App Store optimization)

---

### 2. Stripe SDK Optimization (Estimated savings: 5-10MB)

**Current State:**
- stripe-ios v25.0.0
- Importing Stripe, StripePayments, and StripePaymentSheet

**Recommendations:**

#### Use Selective Import
Only import the specific Stripe modules you need:

```swift
// Review file: burner/Extensions/Services/StripePaymentService.swift:1

// Instead of importing all Stripe modules:
import Stripe
import StripePayments
import StripePaymentSheet

// Only import what each file actually uses
```

#### Consider Stripe Elements Alternative
- If only using basic payment forms, Stripe's web-based Elements might suffice
- Embed in a WKWebView instead of native SDK
- Trade-off: Slightly worse UX for significant size reduction

**Action Items:**
- [ ] Audit which Stripe modules are actually used in StripePaymentService.swift
- [ ] Remove unused Stripe imports across the codebase
- [ ] Consider payment form alternatives for simple use cases

---

### 3. Image Asset Optimization (Estimated savings: 3-5MB)

**Current Issues:**

#### Missing Main App Asset Catalog
The main `burner` app has **NO Assets.xcassets directory**. This is unusual and may indicate:
- App icon being embedded incorrectly
- Missing asset catalog optimizations

**Action Items:**
- [ ] Create `/home/user/BurnerApp/burner/Assets.xcassets/`
- [ ] Add proper app icon asset with all required sizes
- [ ] Use asset catalogs for colors instead of hardcoded values
- [ ] Enable "Optimize for App Store" in asset settings

#### Widget Extension Icon Duplicates
The widget has 3 identical 34KB icon files:
```
TicketWidgetExtension/Assets.xcassets/AppIcon.appiconset/
├── AppIcon.jpg (34KB)
├── AppIcon 1.jpg (34KB) - IDENTICAL
└── AppIcon 2.jpg (34KB) - IDENTICAL
```

All three files have the same MD5 hash but are named for dark/tinted modes.

**Action Items:**
- [ ] Create actual dark and tinted mode variants (or remove if not needed)
- [ ] Use PNG instead of JPG for app icons (better quality, similar size)
- [ ] Compress images using ImageOptim or similar tool

#### Splash Video
- `burner/splash.mp4` is 808KB
- Consider if this is necessary or could be smaller
- Could use lighter animated graphic instead

**Action Items:**
- [ ] Re-encode splash.mp4 at lower bitrate (target: 400-500KB)
- [ ] Consider HEVC (H.265) encoding for better compression
- [ ] Evaluate if animated PNG or Lottie animation would be lighter

---

### 4. Remove Unnecessary Files from Repository (Immediate savings: 2.5MB)

**Files that should NOT be in the iOS bundle:**

```
burner ui.indd - 2.5MB (Adobe InDesign design file)
burner-dashboard/ - 610KB (Next.js web dashboard)
burnercloud/ - 215KB (Firebase Cloud Functions)
```

**CRITICAL:** The InDesign file is currently tracked in git and will be included in the Xcode project if not properly excluded.

**Action Items:**
- [ ] Delete `burner ui.indd` from repository
- [ ] Add to `.gitignore`:
  ```
  *.indd
  *.psd
  *.ai
  *.sketch
  **/burner-dashboard
  **/burnercloud
  ```
- [ ] Verify Xcode build settings exclude these directories
- [ ] Move design files to separate design assets repository

---

## 🟡 Medium Impact Opportunities

### 5. Google Sign-In Optimization (Estimated savings: 3-5MB)

**Current State:**
- GoogleSignIn-iOS v9.0.0
- Includes multiple dependencies: AppAuth-iOS, GTMAppAuth, gtm-session-fetcher

**Recommendations:**

#### Evaluate if Google Sign-In is Necessary
Current authentication methods found:
- Email/Password (EmailAuthView.swift)
- Passwordless auth (PasswordlessAuthView.swift)
- Sign In with Apple (supported via entitlements)
- Google Sign-In

**Questions to consider:**
- What percentage of users use Google Sign-In?
- Could you consolidate to just Apple Sign-In + email/password?
- Is the 3-5MB cost worth the authentication option?

**Action Items:**
- [ ] Check analytics for Google Sign-In usage percentage
- [ ] Consider removing if usage is <10% of authentications
- [ ] If keeping, ensure you're not importing unused Google components

---

### 6. Kingfisher Image Loading Library (Estimated savings: 2-3MB)

**Current State:**
- Kingfisher v8.6.1 for image caching and loading

**Recommendations:**

#### Consider iOS Native AsyncImage
iOS 15+ has native `AsyncImage`:
```swift
// Instead of Kingfisher:
AsyncImage(url: URL(string: imageURL)) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
```

**Trade-offs:**
- ❌ Loses advanced caching features
- ❌ Loses GIF support
- ❌ Loses image processing features
- ✅ Saves 2-3MB bundle size
- ✅ One less dependency to maintain

**Alternative:** Keep Kingfisher but audit usage
- Ensure you're only importing it where needed
- Disable unused features in Kingfisher configuration

**Action Items:**
- [ ] Audit how extensively Kingfisher features are used
- [ ] If only using basic caching, consider migration to AsyncImage
- [ ] If keeping Kingfisher, optimize configuration to minimize binary size

---

### 7. Code Scanner Optimization (Estimated savings: 1-2MB)

**Current State:**
- CodeScanner v2.5.2 for QR code scanning
- Used in: `burner/Settings/ScannerView.swift`

**Recommendations:**

#### Consider Native AVFoundation
Apple's AVFoundation supports QR scanning natively:
```swift
// Replace CodeScanner with native AVCaptureMetadataOutput
import AVFoundation
```

**Benefits:**
- Saves 1-2MB
- One less dependency
- More control over camera configuration

**Trade-offs:**
- More code to write/maintain
- CodeScanner provides nicer SwiftUI API

**Action Items:**
- [ ] Evaluate complexity of ScannerView.swift implementation
- [ ] If simple QR-only scanning, migrate to AVFoundation
- [ ] If complex multi-format scanning, keep CodeScanner

---

### 8. Build Configuration Optimization

**Recommendations:**

#### Enable Swift Optimization Levels
Check project build settings:
```
Optimization Level (Release): -O (Optimize for Speed)
Consider: -Osize (Optimize for Size) - can save 10-20%
```

**Trade-off:** Slightly slower app performance for smaller binary

#### Enable App Thinning
Ensure these are enabled in build settings:
- ✅ Enable Bitcode (if all dependencies support it)
- ✅ Asset Catalog Compiler - Optimization: Space
- ✅ Strip Debug Symbols During Copy: YES
- ✅ Strip Swift Symbols: YES
- ✅ Make Strings Read-Only: YES
- ✅ Dead Code Stripping: YES

**Action Items:**
- [ ] Review build settings in burner.xcodeproj
- [ ] Test app with `-Osize` optimization to measure impact
- [ ] Enable all stripping/optimization flags for Release builds
- [ ] Verify bitcode support across all SPM dependencies

---

## 🟢 Low Impact / Strategic Opportunities

### 9. Dependency Consolidation

**Overlapping Functionality:**

Several Google libraries provide overlapping capabilities:
```
GoogleSignIn-iOS + dependencies (4 packages)
Firebase SDK + dependencies (6 packages)
Google Ads SDK (1 package)
```

**Recommendations:**
- Evaluate if Firebase Auth could replace Google Sign-In
- Consider if Google Ads SDK is providing ROI for the bundle size cost
- Consolidate to minimize Google SDK overlap

---

### 10. Device Activity Monitor Extension Size

**Current State:**
- Separate extension target: BurnerDeviceActivityMonitor
- For iOS 18.6+ Screen Time integration

**Recommendations:**

#### Audit Extension Dependencies
Extensions have their own binary. Ensure:
- Extension doesn't duplicate main app frameworks
- Use App Groups to share code instead of duplicating
- Minimize extension-specific dependencies

**Action Items:**
- [ ] Review BurnerDeviceActivityMonitor target build settings
- [ ] Ensure it uses shared frameworks from main app
- [ ] Minimize extension bundle size separately

---

### 11. Widget Extension Optimization

**Current State:**
- TicketWidgetExtensionExtension for Live Activities
- Duplicated entitlements files:
  - `/burner.entitlements.xml` (potentially duplicate)
  - `/TicketWidgetExtension/TIcketWidgetExtension.entitlements` (typo in filename)

**Recommendations:**

#### Clean Up Entitlements
- Remove duplicate `.xml` entitlements file
- Fix typo in `TIcketWidgetExtension.entitlements` → `TicketWidgetExtension.entitlements`
- Ensure widget only includes necessary entitlements

**Action Items:**
- [ ] Delete duplicate entitlements files
- [ ] Rename `TIcketWidgetExtension.entitlements`
- [ ] Audit widget target for unnecessary capabilities

---

## 📊 Measurement & Validation

### Before Starting
1. Build archive and note current app size:
   ```bash
   # In Xcode: Product → Archive
   # Check .ipa size and App Store estimate
   ```

2. Use App Store Connect size report to see:
   - Universal app size
   - Device-specific download sizes
   - Install sizes per device

### After Each Change
1. Rebuild archive
2. Compare sizes
3. Test thoroughly to ensure functionality isn't broken
4. Document savings in this file

### Tools to Use
- **Xcode App Size Report**: Build → Report Navigator
- **emerge.app**: Automated app size monitoring
- **App Store Connect**: Real download/install sizes

---

## 🎯 Recommended Implementation Order

### Phase 1: Quick Wins (1-2 hours)
1. ✅ Remove `burner ui.indd` and update `.gitignore`
2. ✅ Fix duplicate AppIcon images in widget
3. ✅ Create missing Assets.xcassets for main app
4. ✅ Clean up duplicate entitlements files
5. ✅ Enable build optimization flags

**Expected savings: 3-5MB**

### Phase 2: Asset Optimization (2-3 hours)
1. ✅ Optimize splash.mp4 video
2. ✅ Compress all images with ImageOptim
3. ✅ Set up proper asset catalog with compression

**Expected savings: 2-4MB**

### Phase 3: Dependency Audit (4-6 hours)
1. ✅ Audit Firebase module usage
2. ✅ Audit Stripe module usage
3. ✅ Evaluate Google Sign-In necessity
4. ✅ Consider Kingfisher alternatives

**Expected savings: 5-15MB**

### Phase 4: Code Migration (1-2 weeks)
1. ✅ Migrate to selective Firebase imports
2. ✅ Replace unnecessary SDKs with native alternatives
3. ✅ Optimize extension targets

**Expected savings: 10-20MB**

---

## 📝 Tracking Progress

| Optimization | Status | Estimated Savings | Actual Savings | Date Completed |
|--------------|--------|-------------------|----------------|----------------|
| Remove .indd file | 🔲 Not Started | 2.5MB | - | - |
| Fix duplicate icons | 🔲 Not Started | 68KB | - | - |
| Create Assets.xcassets | 🔲 Not Started | 3-5MB | - | - |
| Optimize splash.mp4 | 🔲 Not Started | 300KB | - | - |
| Firebase optimization | 🔲 Not Started | 10-15MB | - | - |
| Stripe optimization | 🔲 Not Started | 5-10MB | - | - |
| Build settings | 🔲 Not Started | 10-20% | - | - |
| Google Sign-In review | 🔲 Not Started | 3-5MB | - | - |
| Kingfisher review | 🔲 Not Started | 2-3MB | - | - |
| CodeScanner review | 🔲 Not Started | 1-2MB | - | - |

---

## 🔗 Additional Resources

- [Apple: Reducing Your App's Size](https://developer.apple.com/documentation/xcode/reducing-your-app-s-size)
- [App Store Size Guidelines](https://developer.apple.com/app-store/app-size/)
- [Firebase iOS Size Impact](https://firebase.google.com/docs/ios/app-size-impact)
- [Swift Package Manager and App Size](https://www.emergetools.com/blog/posts/how-to-reduce-app-size)

---

## ⚠️ Important Notes

1. **Always test thoroughly** after each optimization
2. **Use TestFlight** to verify real download/install sizes
3. **Monitor crash rates** after dependency changes
4. **Keep analytics** to track feature usage before removing SDKs
5. **Document trade-offs** - sometimes features are worth the bundle size

---

## Current Dependency Summary

**Total SPM Dependencies: 19 packages**

**Largest Contributors (estimated):**
1. Firebase SDK (~20-30MB)
2. Stripe iOS (~8-12MB)
3. Google Sign-In (~4-6MB)
4. gRPC Binary (~3-5MB)
5. Kingfisher (~2-3MB)
6. Other (~5-8MB)

**Total estimated dependency size: 40-65MB**

This represents a significant portion of the app bundle and offers the most opportunity for reduction through careful auditing and selective imports.
