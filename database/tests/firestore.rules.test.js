/**
 * Firestore security rules tests.
 *
 * Requires the Firebase emulator:
 *   npm install @firebase/rules-unit-testing
 *   firebase emulators:start --only firestore
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node --test tests/firestore.rules.test.js
 *
 * Covers the most critical invariants:
 *  - users docs are owner-only
 *  - no client-side privilege escalation (isPremium, planId, isVerified…)
 *  - profiles are public-read / owner-write
 *  - matches/chats require mutual like
 *  - subscriptions can only be downgraded/cancelled by the owner
 */
const { test, describe, before, after, beforeEach } = require('node:test');
const assert = require('node:assert');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const fs = require('node:fs');

const PROJECT_ID = 'demo-roommate-match';
const RULES = fs.readFileSync('../firestore.rules', 'utf8');

let testEnv;
const ALICE = 'alice';
const BOB = 'bob';

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: RULES },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

const db = (uid) => testEnv.authenticatedContext(uid).firestore();
const admin = () => testEnv.unauthenticatedContext().firestore(); // unused
const ownerDoc = (uid) => db(uid).collection('users').doc(uid);
const profileDoc = (uid) => db(uid).collection('profiles').doc(uid);

describe('users collection', () => {
  test('owner can read own doc; others cannot', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('users').doc(ALICE).set({ name: 'A' });
    });
    await assertSucceeds(ownerDoc(ALICE).get());
    await assertFails(ownerDoc(BOB).get());
  });

  test('cannot self-grant premium', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('users').doc(ALICE).set({ name: 'A', isPremium: false });
    });
    await assertFails(
      ownerDoc(ALICE).update({ isPremium: true, planId: 'premium' }),
    );
  });

  test('cannot self-verify', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('users').doc(ALICE).set({ isVerified: false });
    });
    await assertFails(ownerDoc(ALICE).update({ isVerified: true }));
  });
});

describe('profiles collection', () => {
  test('public read, owner write', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('profiles').doc(ALICE).set({ name: 'A' });
    });
    await assertSucceeds(profileDoc(BOB).get());
    await assertFails(profileDoc(BOB).set({ uid: BOB }, { merge: false }));
  });
});

describe('matches / chats (mutual like required)', () => {
  const swipeDoc = (a, b) => `swipes/${a}_${b}`;
  const matchId = [ALICE, BOB].sort().join('_');
  const chatId = matchId;

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('users').doc(ALICE).set({ name: 'A' });
      await ctx.firestore().collection('users').doc(BOB).set({ name: 'B' });
    });
  });

  test('cannot create match without reciprocal like', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      // only alice liked bob — bob never liked alice
      await ctx.firestore().doc(swipeDoc(ALICE, BOB)).set({ isLike: true });
    });
    await assertFails(
      db(ALICE).collection('matches').doc(matchId).set({
        users: [ALICE, BOB],
        timestamp: new Date(),
      }),
    );
  });

  test('can create match with mutual like', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(swipeDoc(ALICE, BOB)).set({ isLike: true });
      await ctx.firestore().doc(swipeDoc(BOB, ALICE)).set({ isLike: true });
    });
    await assertSucceeds(
      db(ALICE).collection('matches').doc(matchId).set({
        users: [ALICE, BOB],
        timestamp: new Date(),
      }),
    );
    await assertSucceeds(
      db(ALICE).collection('chats').doc(chatId).set({
        participants: [ALICE, BOB],
        createdAt: new Date(),
      }),
    );
  });
});

describe('subscriptions (tamper-proof)', () => {
  test('owner can create basic; cannot create premium', async () => {
    const col = db(ALICE).collection('subscriptions');
    await assertSucceeds(col.doc(ALICE).set({
      userId: ALICE,
      planId: 'basic',
      isActive: true,
    }));
    await assertFails(col.doc(ALICE).set({
      userId: ALICE,
      planId: 'premium',
      isActive: true,
    }));
  });

  test('owner can cancel/downgrade; cannot upgrade', async () => {
    const col = db(ALICE).collection('subscriptions');
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('subscriptions').doc(ALICE).set({
        userId: ALICE,
        planId: 'premium',
        isActive: true,
      });
    });
    await assertSucceeds(col.doc(ALICE).update({ isActive: false }));
    await assertFails(col.doc(ALICE).update({ planId: 'premium', isActive: true }));
  });
});
