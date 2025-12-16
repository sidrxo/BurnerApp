# Supabase Migration Status

This document tracks the progress of migrating the burner-dashboard from Firebase to Supabase.

## ✅ Completed

### 1. **Infrastructure Setup**
- ✅ Installed `@supabase/supabase-js` package
- ✅ Created `/lib/supabase.ts` configuration file with type definitions
- ✅ Created `.env.local.example` template

### 2. **Authentication**
- ✅ Migrated `/components/useAuth.tsx` to use Supabase Auth
  - Replaced Firebase `onAuthStateChanged` with Supabase `onAuthStateChange`
  - Query `admins` and `users` tables instead of using custom JWT claims
  - Maintained retry logic for profile loading
  - Original backed up to `useAuth-firebase-backup.tsx`

- ✅ Migrated `/components/login-form.tsx` to use Supabase
  - Replaced `signInWithEmailAndPassword` with `supabase.auth.signInWithPassword`
  - Query Supabase tables for active status checks
  - Updated error handling for Supabase-specific errors
  - Original backed up to `login-form-firebase-backup.tsx`

- ✅ Migrated `/components/require-auth.tsx` to use Supabase
  - Simplified to use AuthProvider context
  - Original backed up to `require-auth-firebase-backup.tsx`

### 3. **Navigation**
- ✅ Updated `/components/app-navbar.tsx` to use Supabase
  - Replaced Firestore venue queries with Supabase queries
  - Replaced `signOut(auth)` with `supabase.auth.signOut()`

### 4. **Database Hooks**

#### ✅ Completed Hooks:

**`/hooks/useEventsData.ts`** - Fully migrated with performance improvements
- ✅ Query events with role-based filtering
- ✅ Venue caching for faster lookups
- ✅ Selective field queries (only fetch needed columns)
- ✅ Database-side ordering
- ✅ Supabase Storage for event images
- ✅ CRUD operations (create/update/delete events)
- ✅ Featured event management
- ✅ Updated field names (camelCase → snake_case)

**`/hooks/useAccountData.ts`** - Fully migrated
- ✅ Password management using Supabase Auth
- ✅ Password strength validation
- ✅ Sign out functionality
- ✅ User profile display

**`/hooks/useVenuesData.ts`** - Fully migrated
- ✅ Uses Supabase Edge Function 'create-venue'
- ✅ Admin management with admins table
- ✅ PostgreSQL array handling for admins
- ✅ JSONB coordinates instead of GeoPoint
- ✅ Role-based query optimization

## 🚧 Remaining Hooks to Migrate

#### `/hooks/useTagManagement.ts`
**Operations needed:**
- Replace Firestore `collection()`, `doc()`, `getDocs()`, `getDoc()` with Supabase queries
- Replace `Timestamp` with ISO date strings or PostgreSQL timestamps
- Replace `setDoc()`, `updateDoc()`, `deleteDoc()` with Supabase `.insert()`, `.update()`, `.delete()`
- Replace Firebase Storage with Supabase Storage for image uploads
- Update query patterns: `where()`, `orderBy()` → `.eq()`, `.order()`

#### `/hooks/useTicketsData.ts`
**Operations to migrate:**
- Load tickets with pagination (50 per page)
- Real-time ticket updates (onSnapshot → realtime subscription)
- Filter by date range
- Group tickets by event
- Mark tickets as used
- Calculate ticket statistics
- Export ticket data

#### `/hooks/useVenuesData.ts`
**Operations to migrate:**
- CRUD operations for venues
- Manage venue admins
- Update venue coordinates

#### `/hooks/useAdminManagement.ts`
**Operations to migrate:**
- Create/update/delete admins
- Create/update/delete scanners
- Call Cloud Functions → Call Supabase Edge Functions
  - `createAdmin` → `/create-admin` edge function (needs to be created)
  - `updateAdmin` → direct database update
  - `deleteAdmin` → edge function for auth cleanup

#### `/hooks/useTagManagement.ts`
**Operations to migrate:**
- CRUD operations for tags
- Reorder tags
- Cloud Functions → Edge Functions or direct database operations

#### `/hooks/useOverviewData.ts`
**Operations to migrate:**
- Dashboard analytics queries
- Revenue calculations
- Ticket statistics
- User activity metrics
- May need to create database views or functions for complex aggregations

#### `/hooks/useAccountData.ts`
**Operations to migrate:**
- Change password functionality
- Update user profile
- Firebase Auth → Supabase Auth password change

### 5. **Storage Operations**
- 🚧 Migrate Firebase Storage to Supabase Storage
  - Event image uploads
  - Image deletion on event update
  - Storage bucket configuration
  - Update storage paths and URLs

### 6. **Edge Functions**
Some operations currently use Firebase Cloud Functions and need to:
- ✅ Use existing Supabase Edge Functions (scan-ticket, payment functions, etc.)
- 🚧 Create new Edge Functions where needed (admin management, etc.)
- 🚧 Update function call patterns from `httpsCallable()` to `supabase.functions.invoke()`

## 📋 Database Schema Mapping

### Firestore → Supabase

| Firestore Collection | Supabase Table | Notes |
|---------------------|----------------|-------|
| `events` | `events` | camelCase → snake_case fields |
| `tickets` | `tickets` | Use ticket_id as primary key |
| `venues` | `venues` | Coordinates as JSONB |
| `admins` | `admins` | Role-based access |
| `users` | `users` | User profiles |
| `tags` | `tags` | Event categorization |
| `eventStats` | `event_stats` or view | Aggregated data |

### Field Naming Convention
- Firebase/Firestore: `camelCase` (e.g., `startTime`, `venueId`)
- Supabase: `snake_case` (e.g., `start_time`, `venue_id`)

**Important:** All database queries need field name conversion!

## 🔐 Environment Variables

### Required for Supabase:
```bash
NEXT_PUBLIC_SUPABASE_URL=your-project-url.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

### Legacy Firebase (can be removed after full migration):
```bash
NEXT_PUBLIC_FIREBASE_API_KEY=...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
NEXT_PUBLIC_FIREBASE_PROJECT_ID=...
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=...
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=...
NEXT_PUBLIC_FIREBASE_APP_ID=...
```

## 🎯 Next Steps

1. **Set up environment variables** - Copy `.env.local.example` to `.env.local` and fill in Supabase credentials
2. **Migrate useEventsData hook** - This is the largest and most critical hook
3. **Migrate useTicketsData hook** - Includes real-time subscriptions
4. **Migrate remaining hooks** - Admin management, venues, tags, overview, account
5. **Create missing Edge Functions** - For admin management operations
6. **Migrate storage operations** - Event image uploads
7. **Test thoroughly** - Each feature needs testing after migration
8. **Remove Firebase dependencies** - Once migration is complete and tested

## 📚 Reference Documentation

- [Supabase JS Client Docs](https://supabase.com/docs/reference/javascript)
- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Supabase Database](https://supabase.com/docs/guides/database)
- [Supabase Storage](https://supabase.com/docs/guides/storage)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime)

## ⚠️ Breaking Changes & Considerations

1. **Authentication flow** - Users will need to be migrated to Supabase Auth (handled by triggers)
2. **Session management** - Supabase uses different session handling
3. **Real-time updates** - Different API from Firestore onSnapshot
4. **Field naming** - camelCase vs snake_case requires field mapping
5. **Date handling** - Timestamp objects vs ISO strings/PostgreSQL timestamps
6. **Query patterns** - Different syntax and capabilities
7. **Storage URLs** - Different URL structure for uploaded files

## 🔄 Rollback Plan

All original Firebase files have been backed up with `-firebase-backup` suffix:
- `components/useAuth-firebase-backup.tsx`
- `components/login-form-firebase-backup.tsx`
- `components/require-auth-firebase-backup.tsx`

To rollback, simply rename these files back to their original names.
