/**
 * Purge ALL seeded demo data from Firestore.
 *
 * Deletes:
 *   - `profiles` docs with isDemo == true
 *   - `swipes` docs flagged isDemo or involving a demo profile
 *   - `matches`/`chats` docs involving a demo profile (incl. messages)
 *
 * Usage:
 *   node scripts/purge-demo-data.js           # dry-run: only counts
 *   node scripts/purge-demo-data.js --delete  # actually deletes
 *
 * Runs with the Admin SDK so Firestore rules do not apply.
 */
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

// --- Load backend/.env (no dotenv dep needed) ---
const envFile = path.join(__dirname, '..', '.env');
for (const line of fs.readFileSync(envFile, 'utf8').split('\n')) {
  const idx = line.indexOf('=');
  if (idx <= 0 || line.trim().startsWith('#')) continue;
  const key = line.slice(0, idx).trim();
  let val = line.slice(idx + 1).trim();
  if (val.startsWith('"') && val.endsWith('"')) val = val.slice(1, -1);
  if (!process.env[key]) process.env[key] = val;
}

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    privateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
  }),
});

const db = admin.firestore();
const DRY_RUN = !process.argv.includes('--delete');

/** Deletes refs in <=500-doc batches. Returns deleted count. */
async function deleteRefs(refs) {
  let deleted = 0;
  for (let i = 0; i < refs.length; i += 500) {
    const batch = db.batch();
    for (const ref of refs.slice(i, i + 500)) batch.delete(ref);
    if (!DRY_RUN) await batch.commit();
    deleted += refs.slice(i, i + 500).length;
  }
  return deleted;
}

/** Deletes a chat doc + its messages subcollection. */
async function deleteChat(chatRef) {
  const msgs = await chatRef.collection('messages').limit(1000).get();
  await deleteRefs(msgs.docs.map((d) => d.ref));
  await deleteRefs([chatRef]);
}

(async () => {
  const stats = { profiles: 0, swipes: 0, matches: 0, chats: 0 };

  // --- Demo profiles ---
  const demoSnap = await db
    .collection('profiles')
    .where('isDemo', '==', true)
    .get();
  const demoIds = new Set(demoSnap.docs.map((d) => d.id));
  console.log(`Perfiles demo encontrados: ${demoIds.size}`);

  // --- Swipes: flagged isDemo OR touching a demo id ---
  const swipeRefs = new Map();
  const flagged = await db
    .collection('swipes')
    .where('isDemo', '==', true)
    .get();
  for (const d of flagged.docs) swipeRefs.set(d.id, d.ref);

  // Unflagged orphans (demo ids that lost their isDemo marker)
  const idChunks = [...demoIds];
  for (let i = 0; i < idChunks.length; i += 30) {
    const chunk = idChunks.slice(i, i + 30);
    if (chunk.length === 0) break;
    const [asSwiper, asSwiped] = await Promise.all([
      db.collection('swipes').where('swiperId', 'in', chunk).get(),
      db.collection('swipes').where('swipedId', 'in', chunk).get(),
    ]);
    for (const d of [...asSwiper.docs, ...asSwiped.docs]) {
      swipeRefs.set(d.id, d.ref);
    }
  }
  console.log(`Swipes demo encontrados: ${swipeRefs.size}`);

  // --- Matches + chats involving a demo id (full scans; small colls) ---
  const matchRefs = [];
  const chatRefs = new Map();
  const matches = await db.collection('matches').get();
  for (const d of matches.docs) {
    const users = d.data().users ?? [];
    if (d.data().isDemo === true || users.some((u) => demoIds.has(u))) {
      matchRefs.push(d.ref);
      chatRefs.set(d.id, db.collection('chats').doc(d.id));
    }
  }
  const chats = await db.collection('chats').get();
  for (const d of chats.docs) {
    const parts = d.data().participants ?? [];
    if (d.data().isDemo === true || parts.some((u) => demoIds.has(u))) {
      chatRefs.set(d.id, d.ref);
    }
  }
  console.log(
    `Matches demo: ${matchRefs.length} | Chats demo: ${chatRefs.size}`,
  );

  if (DRY_RUN) {
    console.log('\nDRY-RUN: nada borrado. Re-ejecuta con --delete.');
    return;
  }

  stats.profiles = await deleteRefs(demoSnap.docs.map((d) => d.ref));
  stats.swipes = await deleteRefs([...swipeRefs.values()]);
  stats.matches = await deleteRefs(matchRefs);
  for (const ref of chatRefs.values()) {
    await deleteChat(ref);
    stats.chats++;
  }

  console.log('\nPurga completada:', stats);
})().catch((e) => {
  console.error('Error en la purga:', e);
  process.exit(1);
});
