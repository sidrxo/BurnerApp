# Deployment Guide - Fix Permissions and Deploy Functions

This guide will help you deploy the fixed Firestore security rules and Cloud Functions to resolve the permissions errors.

## Issues Fixed

1. ✅ **Custom claims** - Added scripts to set proper custom claims on admin accounts
2. ✅ **Firestore rules** - Added missing rules for `/events/{eventId}/tickets/{ticketId}` subcollection
3. ✅ **Cloud Functions** - Added missing `requireAuth` and `requireSiteAdmin` permission helpers

## Prerequisites

- Firebase CLI installed: `npm install -g firebase-tools`
- Logged in to Firebase: `firebase login`
- Correct Firebase project selected

## Step 1: Verify Firebase Project

```bash
cd burnercloud
firebase projects:list
```

Make sure you're deploying to the correct project (likely `burner-34556` based on your error logs).

If needed, set the project:
```bash
firebase use burner-34556
```

## Step 2: Deploy Firestore Security Rules

This will update the rules to include the missing tickets subcollection permissions.

```bash
cd burnercloud
firebase deploy --only firestore:rules
```

**What this does:**
- Adds security rules for `/events/{eventId}/tickets/{ticketId}` subcollection
- Allows siteAdmins to read all tickets via collection groups
- Allows venue admins to read tickets only for their venue's events

## Step 3: Deploy Cloud Functions

This will deploy the tag management functions and other Cloud Functions with the fixed permission helpers.

```bash
cd burnercloud
firebase deploy --only functions
```

**What this does:**
- Deploys all Cloud Functions including `createTag`, `updateTag`, `deleteTag`, `reorderTags`
- Includes the fixed `requireAuth` and `requireSiteAdmin` helpers

**Note:** This may take 5-10 minutes depending on how many functions need to be deployed.

## Step 4: Verify Deployment

After deployment completes, you should see output like:

```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/burner-34556/overview
Functions:
  - createTag(us-central1): https://us-central1-burner-34556.cloudfunctions.net/createTag
  - updateTag(us-central1): https://us-central1-burner-34556.cloudfunctions.net/updateTag
  ...
```

## Step 5: Test in Dashboard

1. **Refresh your dashboard** (hard refresh: Cmd+Shift+R or Ctrl+Shift+R)
2. The overview should now load without permission errors
3. Try creating a tag - it should work without 404 errors

## Troubleshooting

### If you still get permission errors after deploying:

1. **Check browser console** (F12) for the actual error message
2. **Sign out and back in** to refresh your token
3. **Verify custom claims** are set:
   ```bash
   node verify-token.js your-email@example.com
   ```

### If functions still return 404:

1. **Check the function was deployed:**
   ```bash
   cd burnercloud
   firebase functions:list
   ```

2. **Check function logs for errors:**
   ```bash
   firebase functions:log --only createTag
   ```

3. **Verify the function region matches:**
   - Your error showed: `us-central1-burner-34556.cloudfunctions.net`
   - Make sure functions are deployed to `us-central1` (default)

### If deployment fails with "permission denied":

You may need to re-authenticate or check your Firebase project permissions:
```bash
firebase login --reauth
firebase projects:list
```

## Quick Deploy (All at Once)

If you want to deploy everything at once:

```bash
cd burnercloud
firebase deploy
```

This deploys:
- Firestore rules
- All Cloud Functions

## Rollback (If Something Goes Wrong)

If you need to rollback, Firebase keeps previous versions:

1. Go to Firebase Console → Firestore → Rules
2. Click "History" tab
3. Select a previous version and click "Restore"

For functions:
1. Go to Firebase Console → Functions
2. Select a function
3. Click "Version history" to rollback

## Environment Check

Before deploying, verify your environment variables are set in `burnercloud/functions/.env`:

```bash
cd burnercloud/functions
cat .env
```

Should contain:
- `STRIPE_SECRET_KEY`
- Any other API keys your functions need

---

## Summary

Run these commands in order:

```bash
# 1. Verify project
cd burnercloud
firebase use burner-34556

# 2. Deploy rules
firebase deploy --only firestore:rules

# 3. Deploy functions
firebase deploy --only functions

# 4. Verify
firebase functions:list
```

After deployment, refresh your dashboard and the errors should be gone! 🎉
