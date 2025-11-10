#!/usr/bin/env node
/**
 * Verify Token and Custom Claims Script
 *
 * This script verifies that an admin user has the correct custom claims set in Firebase Auth.
 * Use this to debug permission issues.
 *
 * Usage:
 *   node verify-token.js <email>
 *
 * Example:
 *   node verify-token.js admin@example.com
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Initialize Firebase Admin SDK
const serviceAccountPath = path.join(__dirname, 'burnercloud', 'functions', 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('❌ Error: serviceAccountKey.json not found at:', serviceAccountPath);
  console.error('Please ensure your Firebase service account key is in burnercloud/functions/serviceAccountKey.json');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath))
});

const auth = admin.auth();
const db = admin.firestore();

async function verifyToken(email) {
  try {
    console.log('\n' + '='.repeat(70));
    console.log('VERIFYING TOKEN FOR:', email);
    console.log('='.repeat(70) + '\n');

    // Step 1: Get user from Auth
    console.log('📋 Step 1: Looking up user in Firebase Auth...');
    const userRecord = await auth.getUserByEmail(email);
    console.log(`✅ Found user: ${userRecord.uid}`);
    console.log(`   Email verified: ${userRecord.emailVerified}`);
    console.log(`   Disabled: ${userRecord.disabled}`);
    console.log(`   Created: ${userRecord.metadata.creationTime}`);
    console.log(`   Last sign-in: ${userRecord.metadata.lastSignInTime || 'Never'}`);

    // Step 2: Check custom claims
    console.log('\n📋 Step 2: Checking custom claims in Auth token...');
    const customClaims = userRecord.customClaims || {};

    if (Object.keys(customClaims).length === 0) {
      console.log('❌ NO CUSTOM CLAIMS FOUND!');
      console.log('   This is the problem. The user has no role/permissions in their token.');
      console.log('   Run: node fix-admin-claims.js ' + email);
    } else {
      console.log('✅ Custom claims found:');
      console.log(JSON.stringify(customClaims, null, 2));

      // Validate required fields
      console.log('\n📋 Validating required fields...');
      const issues = [];

      if (!customClaims.role) {
        issues.push('❌ Missing "role" field');
      } else if (!['siteAdmin', 'venueAdmin', 'subAdmin', 'scanner'].includes(customClaims.role)) {
        issues.push(`❌ Invalid role: "${customClaims.role}"`);
      } else {
        console.log(`✅ role: "${customClaims.role}"`);
      }

      if (customClaims.active !== true) {
        issues.push('❌ Missing or invalid "active" field (should be true)');
      } else {
        console.log(`✅ active: true`);
      }

      if (customClaims.role === 'venueAdmin' || customClaims.role === 'subAdmin' || customClaims.role === 'scanner') {
        if (!customClaims.venueId) {
          issues.push(`⚠️  Warning: ${customClaims.role} should have a venueId`);
        } else {
          console.log(`✅ venueId: "${customClaims.venueId}"`);
        }
      }

      if (issues.length > 0) {
        console.log('\n⚠️  ISSUES FOUND:');
        issues.forEach(issue => console.log('   ' + issue));
        console.log('\n   Run: node fix-admin-claims.js ' + email);
      }
    }

    // Step 3: Check Firestore document
    console.log('\n📋 Step 3: Checking Firestore admin document...');
    const adminDoc = await db.collection('admins').doc(userRecord.uid).get();

    if (!adminDoc.exists) {
      console.log('❌ NO FIRESTORE DOCUMENT FOUND!');
      console.log('   The /admins/{uid} document does not exist.');
      console.log('   Run: node fix-admin-claims.js ' + email);
    } else {
      const adminData = adminDoc.data();
      console.log('✅ Firestore document found:');
      console.log(JSON.stringify(adminData, null, 2));

      // Compare Firestore vs Token
      console.log('\n📋 Step 4: Comparing Firestore data vs Token claims...');
      const mismatches = [];

      if (adminData.role !== customClaims.role) {
        mismatches.push(`Role mismatch: Firestore="${adminData.role}" vs Token="${customClaims.role}"`);
      }

      if (adminData.active !== customClaims.active) {
        mismatches.push(`Active mismatch: Firestore="${adminData.active}" vs Token="${customClaims.active}"`);
      }

      if (adminData.venueId !== customClaims.venueId) {
        mismatches.push(`VenueId mismatch: Firestore="${adminData.venueId}" vs Token="${customClaims.venueId}"`);
      }

      if (mismatches.length > 0) {
        console.log('⚠️  MISMATCHES FOUND:');
        mismatches.forEach(m => console.log('   ❌ ' + m));
        console.log('\n   Run: node fix-admin-claims.js ' + email);
      } else {
        console.log('✅ Firestore and Token are in sync');
      }
    }

    // Step 5: Test Firestore security rules
    console.log('\n📋 Step 5: Summary for debugging...');
    console.log('\nFor security rules to work, the token MUST have:');
    console.log('   • request.auth.token.role == "siteAdmin"');
    console.log('   • request.auth.token.active == true');

    if (customClaims.role === 'siteAdmin' && customClaims.active === true) {
      console.log('\n✅ Token claims are CORRECT for siteAdmin access!');
      console.log('\nIf you are still getting permission errors:');
      console.log('   1. Sign out of the dashboard completely');
      console.log('   2. Close all browser tabs');
      console.log('   3. Clear browser cache (optional)');
      console.log('   4. Sign back in');
      console.log('   5. Open browser console (F12) and check for logs:');
      console.log('      - "Extracted claims from token:"');
      console.log('      - "User from token extraction:"');
      console.log('   6. Verify the console shows role: "siteAdmin"');
    } else {
      console.log('\n❌ Token claims are INCORRECT!');
      console.log('   Run: node fix-admin-claims.js ' + email);
    }

    console.log('\n' + '='.repeat(70) + '\n');

  } catch (error) {
    console.error('\n❌ Error:', error.message);

    if (error.code === 'auth/user-not-found') {
      console.error('\n💡 User not found. Create one with:');
      console.error('   node fix-admin-claims.js ' + email);
    }
    throw error;
  }
}

// Main execution
const email = process.argv[2];

if (!email) {
  console.error('Usage: node verify-token.js <email>');
  console.error('Example: node verify-token.js admin@example.com');
  process.exit(1);
}

if (!email.includes('@')) {
  console.error('Invalid email address');
  process.exit(1);
}

verifyToken(email)
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
