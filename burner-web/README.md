

## Project Structure

```
burner-web/
├── app/
│   ├── page.tsx              # Home/Explore page
│   ├── signin/               # Authentication page
│   ├── events/
│   │   └── [eventId]/
│   │       ├── page.tsx      # Event detail
│   │       └── purchase/
│   │           └── page.tsx  # Ticket purchase
│   ├── my-tickets/
│   │   └── page.tsx          # User's tickets
│   ├── layout.tsx            # Root layout
│   └── globals.css           # Global styles
├── components/
│   ├── useAuth.tsx           # Authentication context
│   ├── public-nav.tsx        # Navigation bar
│   └── public/
│       └── event-card.tsx    # Event card component
├── hooks/
│   └── usePublicEvents.ts    # Events data hook
└── lib/
    └── firebase.ts           # Firebase configuration
```

## Pages

### Public Pages (No Login Required)

- **`/`** - Home/Explore page with all events
- **`/events/[eventId]`** - Event detail page
- **`/signin`** - Sign in or sign up

### Authenticated Pages

- **`/events/[eventId]/purchase`** - Purchase tickets (requires auth)
- **`/my-tickets`** - View purchased tickets (requires auth)

## Design System

### Mobile-First Responsive

- Base: Mobile (< 640px)
- sm: Tablets (≥ 640px)
- md: Small desktops (≥ 768px)
- lg: Desktops (≥ 1024px)
- xl: Large desktops (≥ 1280px)

### Color Scheme

- Background: Black (#000000)
- Foreground: White (#ffffff)
- Cards: white/5 with white/10 borders
- Buttons: White bg, black text

## Payment Integration

Uses Stripe Payment Element for secure card payments:

1. User clicks "Buy Ticket"
2. Creates payment intent via Firebase Function
3. Stripe handles card input securely
4. Confirms payment and creates ticket
5. Redirects to My Tickets

## QR Code Tickets

### Ticket QR Codes

Tickets purchased through the web app include QR codes that can be scanned for entry validation.

**QR Code Format**: Each ticket's QR code contains the ticket ID, which is validated against the Firestore database during scanning.

### Scanner Compatibility

**✅ YES** - The same QR code scanner from the iOS app works with tickets from this web app.

Both platforms use the same:
- QR code validation backend (Firebase Cloud Functions)
- Ticket database structure (Firestore `tickets` collection)
- Security hash algorithm (HMAC-SHA256)
- Validation logic (ticket status, event date, duplicate scan prevention)

The iOS app scanner can validate tickets purchased from either the iOS app or the web app interchangeably.

## Testing

### Test Stripe Cards

- **Success**: `4242 4242 4242 4242`
- **3D Secure**: `4000 0025 0000 3155`
- **Declined**: `4000 0000 0000 9995`

Use any future expiry date and any 3-digit CVC.

## Build for Production

```bash
npm run build
npm start
```

## Tech Stack

- **Framework**: Next.js 15 with App Router
- **Styling**: Tailwind CSS v4
- **Authentication**: Firebase Auth
- **Database**: Firebase Firestore
- **Functions**: Firebase Cloud Functions
- **Payments**: Stripe
- **QR Codes**: qrcode library
- **Notifications**: Sonner (toast)

## Firestore Optimization

This app implements several best practices for efficient Firestore usage:

### Query Optimizations

1. **In-Memory Caching** (5-minute TTL)
   - Reduces redundant reads when users navigate between pages
   - Events list is cached for 5 minutes before refetching
   - Significantly reduces read costs for high-traffic periods

2. **Query Limits**
   - Maximum 100 events fetched at once
   - Prevents excessive reads for large event catalogs
   - Ensures consistent performance

3. **Indexed Queries**
   - All queries use composite indexes (see `firestore.indexes.json`)
   - Optimized for common access patterns (status + startTime)

4. **No Real-Time Ticket Availability**
   - Ticket counts are NOT displayed to users
   - Prevents real-time listener overhead
   - Sold-out status handled during purchase attempt
   - Reduces read operations by ~90% compared to live availability displays

### Best Practices for Scaling

- **Avoid displaying live ticket counts** - High-traffic events can generate thousands of reads per minute
- **Use status filtering** - Only fetch `active` events, not entire catalog
- **Implement caching** - Reduce repeated queries for the same data
- **Limit result sets** - Use `limit()` to cap maximum documents per query
- **Index all queries** - Every `where()` + `orderBy()` combination needs an index

## Related Projects

- **burner** - iOS app (SwiftUI)
- **burner-dashboard** - Admin dashboard (Next.js)
- **burnercloud** - Firebase Cloud Functions
