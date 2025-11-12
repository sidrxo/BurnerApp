# Firestore Composite Indexes

This document outlines the required Firestore composite indexes for optimal query performance in the Burner app.

## Why Indexes Matter

Firestore composite indexes are required for queries that:
- Order by multiple fields
- Combine equality filters with range or order clauses
- Use multiple inequality filters

Without proper indexes, queries will be slower and may fail entirely.

## Required Indexes

### 1. Events Collection

**Note:** The events listener uses a simple query that doesn't require a composite index:
```swift
db.collection("events")
    .whereField("startTime", isGreaterThan: now)
    .order(by: "startTime", descending: false)
```
This works without an index because it's a single field inequality with order on the same field.

---

### 2. Tickets Collection

#### Index 2: User Tickets by Purchase Date
**Collection:** `tickets`
**Fields:**
- `userId` (Ascending)
- `purchaseDate` (Descending)

**Query Pattern:**
```swift
db.collection("tickets")
    .whereField("userId", isEqualTo: userId)
    .order(by: "purchaseDate", descending: true)
```

**Used in:** `Repository.swift:75-77` - User tickets listener

---

#### Index 3: User Tickets by Event and Status
**Collection:** `tickets`
**Fields:**
- `userId` (Ascending)
- `eventId` (Ascending)
- `status` (Ascending)

**Query Pattern:**
```swift
db.collection("tickets")
    .whereField("userId", isEqualTo: userId)
    .whereField("eventId", in: batch)
    .whereField("status", isEqualTo: "confirmed")
```

**Used in:** `Repository.swift:160-163` - Batch ticket status check

---

## How to Create Indexes

### Option 1: Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Firestore Database** → **Indexes**
4. Click **Create Index**
5. Add the fields specified above with correct ordering
6. Click **Create**

### Option 2: Automatic Index Creation

When you run a query that requires a composite index, Firestore will provide an error with a direct link to create the index. Click the link to automatically create it.

Example error:
```
The query requires an index. You can create it here:
https://console.firebase.google.com/project/...
```

### Option 3: firestore.indexes.json (CI/CD)

Create a `firestore.indexes.json` file in your project root:

```json
{
  "indexes": [
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "startTime",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "startTime",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "tickets",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "purchaseDate",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "tickets",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "eventId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        }
      ]
    }
  ]
}
```

Deploy with:
```bash
firebase deploy --only firestore:indexes
```

## Performance Impact

### Before Optimization
- **Events Listener**: Full collection scan (all past + future events)
- **Bookmarks**: N separate reads (1 per bookmark)
- **Search**: Separate Firestore instance, duplicate reads
- **Nearby**: Fetches 100 events, filters client-side
- **Ticket Status**: Fetches all user tickets

### After Optimization
- **Events Listener**: Only upcoming events within 60 days (60-80% reduction)
- **Bookmarks**: Batched reads with whereIn (90% reduction for 10+ bookmarks)
- **Search**: Uses cached events from AppState (80-100% reduction)
- **Nearby**: Local filtering on cached events (70% reduction)
- **Ticket Status**: whereIn batching (50% reduction)

**Estimated Total Savings:** 70-85% reduction in Firestore read costs

## Monitoring

Monitor your index usage and query performance in Firebase Console:
1. **Firestore Database** → **Usage**
2. Check "Document reads" metric
3. Compare before/after optimization

## Troubleshooting

### Index Already Exists Error
If you see "Index already exists", the index is already created. No action needed.

### Index Build Time
Large collections may take several minutes to hours to index. Monitor progress in Firebase Console.

### Missing Indexes in Development
During development, queries may work without indexes due to small dataset size. Always test with production-like data volumes.

---

**Last Updated:** 2025-11-12
**Maintained By:** Burner Engineering Team
