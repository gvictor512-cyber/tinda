import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { admin } from '../../common/config/firebase.config';
import { User } from './entities/user.entity';
import { ConsentLog } from './entities/consent-log.entity';
import { DataRequest } from './entities/data-request.entity';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(ConsentLog)
    private consentLogRepository: Repository<ConsentLog>,
    @InjectRepository(DataRequest)
    private dataRequestRepository: Repository<DataRequest>,
  ) {}

  async findByFirebaseUid(firebaseUid: string): Promise<User> {
    return this.usersRepository.findOne({ where: { firebaseUid } });
  }

  async create(firebaseUid: string, email: string): Promise<User> {
    const user = this.usersRepository.create({
      firebaseUid,
      email,
    });
    return this.usersRepository.save(user);
  }

  async logConsent(
    firebaseUid: string,
    consentType: string,
    accepted: boolean,
    metadata?: { ip?: string; userAgent?: string; version?: string },
  ): Promise<{ user: User; log: ConsentLog }> {
    const user = await this.findByFirebaseUid(firebaseUid);
    if (!user) throw new NotFoundException('User not found');

    const fieldMap: Record<string, keyof User> = {
      terms: 'acceptedTermsAt',
      privacy: 'acceptedPrivacyAt',
      cookies: 'acceptedCookiesAt',
    };

    const field = fieldMap[consentType];
    if (field) {
      (user as any)[field] = accepted ? new Date() : null;
    }

    const consent = (user.consent || {}) as Record<string, unknown>;
    consent[consentType] = { accepted, at: new Date().toISOString() };
    user.consent = consent;

    await this.usersRepository.save(user);

    const log = this.consentLogRepository.create({
      userId: user.id,
      firebaseUid,
      consentType,
      accepted,
      version: metadata?.version || '1.0',
      ipAddress: metadata?.ip,
      userAgent: metadata?.userAgent,
    });

    return { user: await this.findByFirebaseUid(firebaseUid), log: await this.consentLogRepository.save(log) };
  }

  async exportData(firebaseUid: string): Promise<Record<string, unknown>> {
    const user = await this.findByFirebaseUid(firebaseUid);
    if (!user) throw new NotFoundException('User not found');

    const consents = await this.consentLogRepository.find({
      where: { firebaseUid },
      order: { createdAt: 'DESC' },
    });

    await this.dataRequestRepository.save(
      this.dataRequestRepository.create({
        userId: user.id,
        firebaseUid,
        requestType: 'export',
        status: 'completed',
        payload: { userEmail: user.email },
        completedAt: new Date(),
      }),
    );

    return {
      user: {
        id: user.id,
        firebaseUid: user.firebaseUid,
        email: user.email,
        displayName: user.displayName,
        phone: user.phone,
        birthDate: user.birthDate,
        isActive: user.isActive,
        isPremium: user.isPremium,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        consent: user.consent,
      },
      consents: consents.map((c) => ({
        consentType: c.consentType,
        accepted: c.accepted,
        version: c.version,
        createdAt: c.createdAt,
      })),
    };
  }

  /**
   * Permanently deletes the account and all associated data:
   *   1. Postgres: the user row is anonymized (PII wiped) and deactivated.
   *   2. Firebase: full cascade with the Admin SDK — Firestore documents,
   *      Storage files and the Auth user (works for email, Google and Apple
   *      accounts alike, no client-side re-authentication needed).
   * A deletion audit log (DataRequest) is kept, which only stores the uid.
   */
  async deleteUser(firebaseUid: string): Promise<DataRequest> {
    const user = await this.findByFirebaseUid(firebaseUid);
    if (!user) throw new NotFoundException('User not found');

    // 1. Postgres: anonymize PII instead of hard-deleting the row so
    //    referential integrity (consent logs, data requests) is preserved.
    user.email = `deleted_${user.id}@deleted.invalid`;
    user.displayName = null;
    user.phone = null;
    user.birthDate = null;
    user.consent = {};
    user.isActive = false;
    user.isPremium = false;
    user.isVerified = false;
    user.deletedAt = new Date();
    await this.usersRepository.save(user);

    // 2. Firebase: full cascade. Each step is isolated so a single failure
    //    does not abort the rest of the cleanup.
    await this.deleteFirebaseData(firebaseUid);

    const request = this.dataRequestRepository.create({
      userId: user.id,
      firebaseUid,
      requestType: 'deletion',
      status: 'completed',
      completedAt: new Date(),
    });

    return this.dataRequestRepository.save(request);
  }

  /**
   * Deletes every piece of Firebase data owned by the user:
   * Auth account, Firestore documents and Storage files.
   * Runs with the Admin SDK so security rules do not apply.
   */
  private async deleteFirebaseData(firebaseUid: string): Promise<void> {
    const db = admin.firestore();
    const errors: string[] = [];

    const safe = async (label: string, fn: () => Promise<unknown>) => {
      try {
        await fn();
      } catch (e) {
        const message = e instanceof Error ? e.message : String(e);
        errors.push(`${label}: ${message}`);
        this.logger.warn(`deleteFirebaseData ${label} failed: ${message}`);
      }
    };

    // Batch-delete helper for filtered collections (chunks of 450 writes).
    const deleteWhere = async (
      collection: string,
      field: string,
      op: FirebaseFirestore.WhereFilterOp,
      value: unknown,
      recursive = false,
    ) => {
      const snap = await db
        .collection(collection)
        .where(field, op, value as never)
        .get();
      if (snap.empty) return;
      if (recursive) {
        for (const doc of snap.docs) {
          await db.recursiveDelete(doc.ref);
        }
        return;
      }
      let batch = db.batch();
      let count = 0;
      for (const doc of snap.docs) {
        batch.delete(doc.ref);
        if (++count === 450) {
          await batch.commit();
          batch = db.batch();
          count = 0;
        }
      }
      if (count > 0) await batch.commit();
    };

    // --- Firestore ---
    await safe('users doc + subcollections', () =>
      db.recursiveDelete(db.collection('users').doc(firebaseUid)));
    await safe('profiles doc', () =>
      db.recursiveDelete(db.collection('profiles').doc(firebaseUid)));
    await safe('subscriptions doc', () =>
      db.collection('subscriptions').doc(firebaseUid).delete());
    await safe('admins doc', () =>
      db.collection('admins').doc(firebaseUid).delete());
    await safe('swipes as swiper', () =>
      deleteWhere('swipes', 'swiperId', '==', firebaseUid));
    await safe('swipes as swiped', () =>
      deleteWhere('swipes', 'swipedId', '==', firebaseUid));
    await safe('matches', () =>
      deleteWhere('matches', 'users', 'array-contains', firebaseUid));
    // Chats and conversations include message subcollections.
    await safe('chats', () =>
      deleteWhere('chats', 'participants', 'array-contains', firebaseUid, true));
    await safe('conversations', () =>
      deleteWhere('conversations', 'participants', 'array-contains', firebaseUid, true));
    await safe('blocked_users (blocker)', () =>
      deleteWhere('blocked_users', 'blockerId', '==', firebaseUid));
    await safe('blocked_users (blocked)', () =>
      deleteWhere('blocked_users', 'blockedId', '==', firebaseUid));
    await safe('listings', () =>
      deleteWhere('listings', 'ownerId', '==', firebaseUid));
    await safe('verification_requests', () =>
      deleteWhere('verification_requests', 'userId', '==', firebaseUid));
    await safe('reports', () =>
      deleteWhere('reports', 'reporterId', '==', firebaseUid));
    await safe('moderation_queue', () =>
      deleteWhere('moderation_queue', 'reporterId', '==', firebaseUid));
    await safe('referrals (referrer)', () =>
      deleteWhere('referrals', 'referrerId', '==', firebaseUid));
    await safe('referrals (referred)', () =>
      deleteWhere('referrals', 'referredId', '==', firebaseUid));
    await safe('feedback', () =>
      deleteWhere('feedback', 'userId', '==', firebaseUid));
    await safe('support_messages', () =>
      deleteWhere('support_messages', 'userId', '==', firebaseUid));
    await safe('purchases', () =>
      deleteWhere('purchases', 'userId', '==', firebaseUid));
    await safe('boosts', () =>
      deleteWhere('boosts', 'userId', '==', firebaseUid));
    await safe('transactions', () =>
      deleteWhere('transactions', 'userId', '==', firebaseUid));
    await safe('user_registrations', () =>
      deleteWhere('user_registrations', 'userId', '==', firebaseUid));
    await safe('subscription_events', () =>
      deleteWhere('subscription_events', 'userId', '==', firebaseUid));
    await safe('analytics_events', () =>
      deleteWhere('analytics_events', 'userId', '==', firebaseUid));

    // --- Storage ---
    // Folders are virtual: every file under each user prefix must go.
    const bucketName =
      process.env.FIREBASE_STORAGE_BUCKET ||
      `${process.env.FIREBASE_PROJECT_ID}.firebasestorage.app`;
    await safe('storage', async () => {
      const bucket = admin.storage().bucket(bucketName);
      for (const prefix of [`users/${firebaseUid}/`, `user_photos/${firebaseUid}/`]) {
        await bucket.deleteFiles({ prefix });
      }
    });

    // --- Auth (last: keeps the account recoverable if a step above fails) ---
    await safe('auth user', () => admin.auth().deleteUser(firebaseUid));

    if (errors.length > 0) {
      this.logger.warn(
        `Partial cleanup for uid=${firebaseUid}: ${errors.join(' | ')}`,
      );
    } else {
      this.logger.log(`Firebase data fully deleted for uid=${firebaseUid}`);
    }
  }

  /**
   * Grants 5 freeLikes per completed, unrewarded referral where the caller
   * is the referrer. Client-side writes to another user's doc are blocked
   * by Firestore rules, so the reward is applied here via the Admin SDK.
   */
  async claimReferralRewards(firebaseUid: string) {
    const db = admin.firestore();
    const pending = await db
      .collection('referrals')
      .where('referrerId', '==', firebaseUid)
      .where('status', '==', 'completed')
      .limit(100)
      .get();

    const unrewarded = pending.docs.filter(
      (d) => d.data().rewarded !== true,
    );
    if (unrewarded.length === 0) {
      return { granted: 0 };
    }

    const likesPerReferral = 5;
    const totalLikes = unrewarded.length * likesPerReferral;

    await db.collection('users').doc(firebaseUid).set(
      { freeLikes: admin.firestore.FieldValue.increment(totalLikes) },
      { merge: true },
    );

    const batch = db.batch();
    for (const doc of unrewarded) {
      batch.update(doc.ref, {
        rewarded: true,
        rewardedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    this.logger.log(
      `Referral rewards granted uid=${firebaseUid} count=${unrewarded.length} likes=${totalLikes}`,
    );
    return { granted: unrewarded.length, freeLikes: totalLikes };
  }
}
