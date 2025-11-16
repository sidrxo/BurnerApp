

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

## Related Projects

- **burner** - iOS app (SwiftUI)
- **burner-dashboard** - Admin dashboard (Next.js)
- **burnercloud** - Firebase Cloud Functions
