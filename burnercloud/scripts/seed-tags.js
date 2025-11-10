#!/usr/bin/env node

/**
 * Script to seed initial tags into Firestore
 * Run with: node scripts/seed-tags.js
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const path = require('path');

// Initialize Firebase Admin with service account
// You'll need to have your service account key at the specified path
const serviceAccountPath = path.join(__dirname, '../serviceAccountKey.json');

try {
  const serviceAccount = require(serviceAccountPath);

  initializeApp({
    credential: cert(serviceAccount)
  });

  console.log('✅ Firebase Admin initialized');
} catch (error) {
  console.error('❌ Error loading service account key:', error.message);
  console.log('ℹ️  Please ensure serviceAccountKey.json is in the burnercloud directory');
  process.exit(1);
}

const db = getFirestore();

// Initial tags to seed
const initialTags = [
  { name: 'Techno', description: 'Electronic dance music', order: 1 },
  { name: 'House', description: 'House music events', order: 2 },
  { name: 'Drum & Bass', description: 'Fast-paced electronic music', order: 3 },
  { name: 'Trance', description: 'Trance music events', order: 4 },
  { name: 'Hip Hop', description: 'Hip hop and rap music', order: 5 },
  { name: 'Garage', description: 'UK garage music', order: 6 },
  { name: 'Bass', description: 'Bass-heavy music events', order: 7 },
  { name: 'Live', description: 'Live music performances', order: 8 },
  { name: 'Comedy', description: 'Comedy shows and events', order: 9 },
  { name: 'Wellness', description: 'Wellness and mindfulness events', order: 10 },
  { name: 'Art', description: 'Art exhibitions and events', order: 11 },
  { name: 'Burner', description: 'Burning Man style events', order: 12 },
];

async function seedTags() {
  try {
    console.log('🌱 Starting tag seeding...\n');

    // Check if tags collection already has data
    const existingTags = await db.collection('tags').limit(1).get();

    if (!existingTags.empty) {
      console.log('⚠️  Tags collection already has data');
      console.log('   To reseed, please manually delete the existing tags first');
      return;
    }

    // Add each tag
    const promises = initialTags.map(async (tag) => {
      const tagData = {
        name: tag.name,
        nameLowercase: tag.name.toLowerCase(),
        description: tag.description || null,
        color: null,
        order: tag.order,
        active: true,
        createdAt: FieldValue.serverTimestamp(),
        createdBy: 'system-seed',
        updatedAt: FieldValue.serverTimestamp(),
      };

      const docRef = await db.collection('tags').add(tagData);
      console.log(`✅ Created tag: ${tag.name} (${docRef.id})`);
      return docRef;
    });

    await Promise.all(promises);

    console.log(`\n🎉 Successfully seeded ${initialTags.length} tags!`);

  } catch (error) {
    console.error('❌ Error seeding tags:', error);
    process.exit(1);
  }
}

// Run the seed function
seedTags()
  .then(() => {
    console.log('\n✨ Seeding complete!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  });
