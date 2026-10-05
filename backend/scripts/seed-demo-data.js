/**
 * Seed demo data for manual testing / App Review recordings.
 *
 * Usage:
 *   node scripts/seed-demo-data.js <user-email> [<user-email> ...]
 *
 * For each target account it creates:
 *   - 10 demo profiles in `profiles` (isDemo: true), opposite userType
 *   - Likes FROM some demo profiles TO the target user (swipes)
 *   - Mutual likes + match docs + chats with real messages
 *   - Ensures the target `users/{uid}` doc has `preferences` set
 *     (getPotentialMatches() returns [] when it is missing)
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
const { FieldValue, GeoPoint, Timestamp } = admin.firestore;

const NAMES = [
  'Lucía', 'Marcos', 'Sofía', 'Daniel', 'Valeria',
  'Pablo', 'Carmen', 'Alejandro', 'Elena', 'Hugo',
];
const BIOS = [
  'Estudiante de arquitectura, tranquila y ordenada.',
  'Trabajo en tecnología, teletrabajo casi todos los días.',
  'Deportista, madrugadora y muy limpia.',
  'Recién llegado a la ciudad por trabajo. Sociable.',
  'Me encanta el yoga, las plantas y los planes de domingo.',
  'Fotógrafo freelance, paso mucho tiempo fuera.',
  'Doctoranda en biología, busco convivencia tranquila.',
  'Amante de los animales y la música.',
  'Cocinero de profesión, la cocina siempre huele bien.',
  'Estudio diseño, me gusta el arte y las exposiciones.',
];
const INTERESTS = [
  'Música', 'Cine', 'Deporte', 'Viajes', 'Cocinar',
  'Lectura', 'Senderismo', 'Fotografía', 'Yoga', 'Arte',
];

const rand = (arr) => arr[Math.floor(Math.random() * arr.length)];
const pairId = (a, b) => (a < b ? `${a}_${b}` : `${b}_${a}`);

async function getUidByEmail(email) {
  try {
    const user = await admin.auth().getUserByEmail(email);
    return user.uid;
  } catch {
    console.log(`  ! No existe usuario Auth con email ${email}, se omite`);
    return null;
  }
}

async function ensureUserDoc(uid) {
  const ref = db.collection('users').doc(uid);
  const doc = await ref.get();
  if (!doc.exists || !doc.data()?.preferences) {
    await ref.set(
      {
        uid,
        userType: doc.data()?.userType ?? 'tenant',
        preferences: {
          ageRange: [18, 40],
          gender: 'all',
          budget: 650,
          maxDistance: 50,
          location: new GeoPoint(40.4168, -3.7038), // Madrid
        },
      },
      { merge: true },
    );
    console.log(`  · users/${uid} completado con preferences por defecto`);
  }
  return (await ref.get()).data() || {};
}

async function ensureDemoProfiles(userData) {
  const existing = await db
    .collection('profiles')
    .where('isDemo', '==', true)
    .get();
  if (existing.size >= 8) {
    console.log(`  · Reutilizando ${existing.size} perfiles demo existentes`);
    return existing.docs.map((d) => ({ id: d.id, ...d.data() }));
  }

  const myType = userData.userType ?? 'tenant';
  const candidateType = myType === 'landlord' ? 'tenant' : 'landlord';
  const myLoc = userData.preferences?.location;
  const baseLat = myLoc?.latitude ?? 40.4168;
  const baseLon = myLoc?.longitude ?? -3.7038;

  const created = [];
  for (let i = 0; i < NAMES.length; i++) {
    const ref = db.collection('profiles').doc();
    const location = new GeoPoint(
      baseLat + (Math.random() - 0.5) * 0.04,
      baseLon + (Math.random() - 0.5) * 0.04,
    );
    const budget = 500 + Math.floor(Math.random() * 400);
    const photos = [
      `https://i.pravatar.cc/800?img=${(i * 6 + 3) % 70 + 1}`,
      `https://picsum.photos/seed/${ref.id}-b/800/1000`,
    ];
    const data = {
      uid: ref.id,
      name: NAMES[i],
      userType: candidateType,
      photoURL: photos[0],
      birthDate: Timestamp.fromDate(new Date(2000 - (i % 10), i % 12, 15)),
      createdAt: FieldValue.serverTimestamp(),
      isActive: true,
      isPremium: false,
      isVerified: false,
      isDemo: true,
      banned: false,
      profile: {
        age: 22 + (i % 15),
        bio: BIOS[i],
        gender: i % 2 === 0 ? 'female' : 'male',
        interests: [rand(INTERESTS), rand(INTERESTS)],
        photos,
      },
      preferences: {
        ageRange: [18, 99],
        gender: 'all',
        budget,
        maxDistance: 100,
        location,
      },
    };
    await ref.set(data);
    created.push({ id: ref.id, ...data });
  }
  console.log(`  · ${created.length} perfiles demo creados`);
  return created;
}

async function seedInteractions(uid, profiles) {
  // 1) Likes demo -> user (so the user can like back and match)
  for (const p of profiles.slice(0, 5)) {
    await db
      .collection('swipes')
      .doc(`${p.id}_${uid}`)
      .set({
        swiperId: p.id,
        swipedId: uid,
        isLike: true,
        isDemo: true,
        timestamp: FieldValue.serverTimestamp(),
      });
  }

  // 2) For 3 profiles: mutual like (user -> demo), match doc, chat + messages
  const withMatch = profiles.slice(0, 3);
  const now = Date.now();
  for (const [i, p] of withMatch.entries()) {
    await db
      .collection('swipes')
      .doc(`${uid}_${p.id}`)
      .set({
        swiperId: uid,
        swipedId: p.id,
        isLike: true,
        isDemo: true,
        timestamp: FieldValue.serverTimestamp(),
      });

    const id = pairId(uid, p.id);
    const lastMsg = `¡Hola! Encantada de haber hecho match, ${p.name}.`;
    await db.collection('matches').doc(id).set({
      users: [uid, p.id],
      timestamp: FieldValue.serverTimestamp(),
      lastMessage: lastMsg,
      lastMessageTimestamp: Timestamp.fromMillis(now - i * 3600_000),
      unreadCount: { [uid]: 1, [p.id]: 0 },
      isDemo: true,
    });

    const chatRef = db.collection('chats').doc(id);
    await chatRef.set({
      participants: [uid, p.id],
      lastMessage: lastMsg,
      lastMessageTimestamp: Timestamp.fromMillis(now - i * 3600_000),
      lastMessageSender: p.id,
      createdAt: FieldValue.serverTimestamp(),
      unreadCounts: { [uid]: 1, [p.id]: 0 },
    });

    const messages = [
      { senderId: p.id, receiverId: uid, message: '¡Hola! He visto tu perfil y me ha encantado 😊', minsAgo: 125 },
      { senderId: uid, receiverId: p.id, message: '¡Hola! Muchas gracias, el tuyo también se ve genial', minsAgo: 120 },
      { senderId: p.id, receiverId: uid, message: '¿Buscas piso por qué zona?', minsAgo: 115 },
      { senderId: uid, receiverId: p.id, message: 'Por el centro, cerca del metro si es posible', minsAgo: 110 },
      { senderId: p.id, receiverId: uid, message: lastMsg, minsAgo: i * 60 + 5 },
    ];
    for (const m of messages) {
      await chatRef.collection('messages').add({
        senderId: m.senderId,
        receiverId: m.receiverId,
        message: m.message,
        imageUrl: null,
        timestamp: Timestamp.fromMillis(now - m.minsAgo * 60_000),
        read: m.senderId === uid,
      });
    }
  }
  console.log(`  · ${Math.min(5, profiles.length)} likes recibidos, ${withMatch.length} matches + chats con mensajes`);
}

(async () => {
  const emails = process.argv.slice(2);
  if (emails.length === 0) {
    console.error('Uso: node scripts/seed-demo-data.js <email> [<email> ...]');
    process.exit(1);
  }

  for (const email of emails) {
    console.log(`\n== ${email}`);
    const uid = await getUidByEmail(email);
    if (!uid) continue;
    const userData = await ensureUserDoc(uid);
    const profiles = await ensureDemoProfiles(userData);
    await seedInteractions(uid, profiles);
    console.log(`  ✓ Listo (uid=${uid})`);
  }
  process.exit(0);
})().catch((e) => {
  console.error('Error en seed:', e);
  process.exit(1);
});
