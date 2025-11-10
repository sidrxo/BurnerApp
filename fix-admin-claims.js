#!/usr/bin/env node
/**
 * Fix Admin Custom Claims Script
 *
 * This script sets custom claims on Firebase Auth users to grant them admin access.
 * Run this when you can't access the dashboard due to insufficient permissions.
 *
 * Usage:
 *   node fix-admin-claims.js <email>
 *
 * Example:
 *   node fix-admin-claims.js admin@example.com
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

async function fixAdminClaims(email) {
  try {
    console.log(`\n🔍 Looking up user: ${email}`);

    // Get user by email
    const userRecord = await auth.getUserByEmail(email);
    console.log(`✅ Found user: ${userRecord.uid}`);

    // Check current custom claims
    console.log('\n📋 Current custom claims:', JSON.stringify(userRecord.customClaims || {}, null, 2));

    // Check Firestore admin document
    const adminDoc = await db.collection('admins').doc(userRecord.uid).get();

    if (!adminDoc.exists) {
      console.log('\n⚠️  No admin document found in Firestore. Creating one...');

      // Create admin document
      await db.collection('admins').doc(userRecord.uid).set({
        email: email,
        name: userRecord.displayName || email.split('@')[0],
        role: 'siteAdmin',
        venueId: null,
        active: true,
        createdAt: new Date(),
        createdBy: 'fix-admin-claims-script',
        needsPasswordReset: false
      });

      console.log('✅ Admin document created in Firestore');
    } else {
      console.log('\n📄 Existing Firestore admin doc:', JSON.stringify(adminDoc.data(), null, 2));
    }

    // Set custom claims
    const customClaims = {
      role: 'siteAdmin',
      active: true
    };

    console.log('\n🔧 Setting custom claims:', JSON.stringify(customClaims, null, 2));
    await auth.setCustomUserClaims(userRecord.uid, customClaims);

    console.log('✅ Custom claims set successfully!');

    // Verify the claims were set
    const updatedUser = await auth.getUser(userRecord.uid);
    console.log('\n✅ Verified custom claims:', JSON.stringify(updatedUser.customClaims, null, 2));

    console.log('\n' + '='.repeat(70));
    console.log('🎉 SUCCESS! Admin account fixed.');
    console.log('='.repeat(70));
    console.log('\n⚠️  IMPORTANT: You MUST sign out and sign back in for changes to take effect!');
    console.log('   Custom claims are part of the ID token, which is cached by the client.');
    console.log('   Signing out and back in will refresh the token with new claims.\n');

  } catch (error) {
    console.error('\n❌ Error:', error.message);

    if (error.code === 'auth/user-not-found') {
      console.error('\n💡 User not found. Creating a new siteAdmin account...\n');
      await createNewAdmin(email);
    } else {
      throw error;
    }
  }
}

async function createNewAdmin(email) {
  try {
    const readline = require('readline').createInterface({
      input: process.stdin,
      output: process.stdout
    });

    const question = (query) => new Promise((resolve) => readline.question(query, resolve));

    const password = await question('Enter password for new admin (min 6 characters): ');
    const displayName = await question('Enter display name (or press Enter to use email): ');

    readline.close();

    if (!password || password.length < 6) {
      throw new Error('Password must be at least 6 characters');
    }

    console.log('\n🔧 Creating new admin user...');

    // Create Auth user
    const userRecord = await auth.createUser({
      email: email,
      password: password,
      displayName: displayName || email.split('@')[0],
      emailVerified: true
    });

    console.log(`✅ Auth user created: ${userRecord.uid}`);

    // Set custom claims
    await auth.setCustomUserClaims(userRecord.uid, {
      role: 'siteAdmin',
      active: true
    });

    console.log('✅ Custom claims set');

    // Create Firestore document
    await db.collection('admins').doc(userRecord.uid).set({
      email: email,
      name: displayName || email.split('@')[0],
      role: 'siteAdmin',
      venueId: null,
      active: true,
      createdAt: new Date(),
      createdBy: 'fix-admin-claims-script',
      needsPasswordReset: false
    });

    console.log('✅ Firestore document created');

    console.log('\n' + '='.repeat(70));
    console.log('🎉 SUCCESS! New siteAdmin account created.');
    console.log('='.repeat(70));
    console.log(`\nEmail: ${email}`);
    console.log(`Password: ${password}`);
    console.log(`\nYou can now sign in to the dashboard with these credentials.\n`);

  } catch (error) {
    console.error('❌ Error creating admin:', error.message);
    throw error;
  }
}

// Main execution
const email = process.argv[2];

if (!email) {
  console.error('Usage: node fix-admin-claims.js <email>');
  console.error('Example: node fix-admin-claims.js admin@example.com');
  process.exit(1);
}

if (!email.includes('@')) {
  console.error('Invalid email address');
  process.exit(1);
}

fixAdminClaims(email)
  .then(() => {
    console.log('Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
