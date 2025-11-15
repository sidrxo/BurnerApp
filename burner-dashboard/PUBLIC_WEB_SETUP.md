# Burner Public Web App - Setup Guide

This document describes the new customer-facing mobile-first web application for Burner.

## Overview

A mobile-first (but fully responsive) public web interface that allows customers to:
- Browse and discover events
- View event details
- Purchase tickets using Stripe
- View their purchased tickets with QR codes

## Architecture

### Route Structure

```
(public)/                    # Public routes (no authentication required)
├── page.tsx                # Home/Explore page
├── events/
│   └── [eventId]/
│       ├── page.tsx        # Event detail page
│       └── purchase/
│           └── page.tsx    # Ticket purchase page
└── my-tickets/
    └── page.tsx            # User's tickets (requires auth)
```

### Key Components

- **PublicNav** (`/components/public-nav.tsx`) - Navigation header
- **EventCard** (`/components/public/event-card.tsx`) - Reusable event card
- **PublicLayout** (`/app/(public)/layout.tsx`) - Public pages layout (no auth required)

### Hooks

- **usePublicEvents** (`/hooks/usePublicEvents.ts`) - Fetches published events from Firestore

## Environment Variables Required

Add the following to your `.env.local` file:

```bash
# Stripe Publishable Key (for frontend)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_...

# Firebase Config (already configured)
NEXT_PUBLIC_FIREBASE_API_KEY=...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
NEXT_PUBLIC_FIREBASE_PROJECT_ID=...
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=...
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=...
NEXT_PUBLIC_FIREBASE_APP_ID=...
```

## Design System

### Mobile-First Approach

All components are built mobile-first using Tailwind CSS with responsive breakpoints:
- **Base**: Mobile (< 640px)
- **sm**: Small tablets (≥ 640px)
- **md**: Tablets (≥ 768px)
- **lg**: Small desktops (≥ 1024px)
- **xl**: Large desktops (≥ 1280px)

### Color Scheme (Matching iOS App)

- **Background**: Black (#000000)
- **Text**: White with opacity variations (white, white/70, white/50, white/30)
- **Cards**: white/5 background with white/10 borders
- **Hover states**: white/10 background with white/20 borders
- **Buttons**:
  - Primary: White background, black text
  - Disabled: white/10 background, white/30 text

### Typography

- **Headers**:
  - Hero: text-4xl to text-6xl (mobile to desktop)
  - Page: text-3xl to text-4xl
  - Section: text-2xl to text-3xl
- **Body**: text-base to text-lg
- **Font Weight**: Bold for headers, medium for buttons

## Payment Flow

1. User views event detail page
2. Clicks "Buy Ticket"
3. If not authenticated, redirects to sign-in with return URL
4. Purchase page:
   - Calls `createPaymentIntent` Cloud Function
   - Displays Stripe Payment Element
   - User enters card details
   - Confirms payment with Stripe
   - Calls `confirmPurchase` Cloud Function
   - Creates ticket in Firestore
5. Redirects to "My Tickets" page

## Features Implemented

### ✅ Explore/Home Page
- Featured events section (large cards)
- All events grid
- Responsive layout (1-4 columns based on screen size)
- Loading and error states

### ✅ Event Detail Page
- Event image hero
- Full event details (name, venue, date, description)
- Price and availability
- "Buy Ticket" button with sold-out handling
- Back navigation

### ✅ Ticket Purchase
- Stripe Payment Element integration
- Dark theme Stripe appearance
- Price summary
- Terms and conditions links
- Loading states
- Error handling with toast notifications

### ✅ My Tickets
- List of user's purchased tickets
- Event details with images
- Ticket status badges (Valid/Used)
- QR code modal for each ticket
- Empty state with CTA to browse events

## Navigation

### Public (Not Signed In)
- Logo → Home
- Sign In button

### Authenticated User
- Logo → Home
- My Tickets → Tickets page
- Dashboard → Admin dashboard (if has permissions)

## Firebase Integration

### Collections Used
- **events**: Published events only (where status == "published")
- **tickets**: User's purchased tickets
- **pendingPayments**: Temporary payment records
- **users**: User Stripe customer IDs

### Cloud Functions Called
- `createPaymentIntent`: Initialize Stripe payment
- `confirmPurchase`: Confirm payment and create ticket

## Responsive Design Examples

```tsx
// Grid that adapts from 1 to 4 columns
<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">

// Text that scales
<h1 className="text-4xl md:text-5xl lg:text-6xl font-bold">

// Padding that increases on larger screens
<div className="px-4 py-8 md:py-12 max-w-7xl mx-auto">
```

## Next Steps

1. **Add environment variable**: Set `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`
2. **Test payment flow**: Use Stripe test cards
3. **Optional enhancements**:
   - Search and filtering on explore page
   - Event categories/tags filtering
   - Location-based filtering
   - Ticket transfer functionality
   - Order history page
   - Email confirmations

## Testing

### Test Cards (Stripe)
- Success: `4242 4242 4242 4242`
- Requires authentication: `4000 0025 0000 3155`
- Declined: `4000 0000 0000 9995`

Use any future expiry date and any 3-digit CVC.

## Deployment

The public web app is part of the Next.js dashboard app but uses a separate route group, so it deploys together. No additional deployment steps needed beyond the main dashboard deployment.
