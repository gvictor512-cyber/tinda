# Firestore Rules Tests

Automated tests for `database/firestore.rules` using `@firebase/rules-unit-testing`
against the Firestore emulator.

## Setup

```bash
cd database/tests
npm install
```

## Run

Terminal 1 — start the emulator:

```bash
firebase emulators:start --only firestore
```

Terminal 2 — run the tests:

```bash
cd database/tests
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm test
```

## Coverage

- `users` — owner-only reads, no self-granted premium/verification
- `profiles` — public read, owner write
- `swipes` — deterministic IDs, mutual-like requirement
- `matches` / `chats` — cannot be created without a reciprocal like
- `subscriptions` — owner may only create `basic`, downgrade or cancel
