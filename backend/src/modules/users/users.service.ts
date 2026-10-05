import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
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

  /**
   * Seeds a complete test scenario for the caller: demo profiles that
   * appear in the swipe deck, incoming likes, mutual matches and chats
   * with two-way messages. Admin SDK bypasses rules so writes that the
   * client can't do (likes written as demo users) work here.
   */
  async seedDemoData(firebaseUid: string): Promise<{
    profiles: number;
    likes: number;
    matches: number;
    messages: number;
  }> {
    const db = admin.firestore();
    const fv = admin.firestore.FieldValue;
    const GeoPoint = admin.firestore.GeoPoint;

    // --- Caller context: userType drives the candidate type ---
    const meRef = db.collection('users').doc(firebaseUid);
    const meSnap = await meRef.get();
    const me = meSnap.data() ?? {};
    if (!me.preferences || typeof me.preferences !== 'object') {
      await meRef.set(
        {
          preferences: {
            ageRange: [18, 40],
            gender: 'all',
            budget: 650,
            maxDistance: 50,
            location: new GeoPoint(40.4168, -3.7038),
          },
        },
        { merge: true },
      );
      me.preferences = {
        ageRange: [18, 40],
        gender: 'all',
        budget: 650,
        maxDistance: 50,
        location: new GeoPoint(40.4168, -3.7038),
      };
    }
    const myType = (me.userType as string) ?? 'tenant';
    const candidateType = myType === 'landlord' ? 'tenant' : 'landlord';
    const myLoc = me.preferences?.location;
    const baseLat = myLoc?.latitude ?? 40.4168;
    const baseLon = myLoc?.longitude ?? -3.7038;
    const myBudget =
      typeof me.preferences?.budget === 'number' ? me.preferences.budget : 650;

    // --- Purge previous demo data (profiles + this user's related docs) ---
    const demoSnap = await db
      .collection('profiles')
      .where('isDemo', '==', true)
      .get();
    const demoIds = new Set(demoSnap.docs.map((d) => d.id));
    if (demoIds.size > 0) {
      const purge = db.batch();
      for (const d of demoSnap.docs) purge.delete(d.ref);

      const swipesA = await db
        .collection('swipes')
        .where('swiperId', '==', firebaseUid)
        .get();
      const swipesB = await db
        .collection('swipes')
        .where('swipedId', '==', firebaseUid)
        .get();
      for (const d of [...swipesA.docs, ...swipesB.docs]) {
        const data = d.data();
        if (demoIds.has(data.swipedId) || demoIds.has(data.swiperId)) {
          purge.delete(d.ref);
        }
      }

      const matches = await db
        .collection('matches')
        .where('users', 'array-contains', firebaseUid)
        .get();
      for (const d of matches.docs) {
        const users: string[] = d.data().users ?? [];
        if (users.some((u) => demoIds.has(u))) {
          purge.delete(d.ref);
          purge.delete(db.collection('chats').doc(d.id));
        }
      }
      await purge.commit();
    }

    // --- Demo content ---
    const names = [
      'Lucía', 'Marcos', 'Sofía', 'Daniel', 'Valeria',
      'Pablo', 'Carmen', 'Alejandro', 'Elena', 'Hugo',
      'Marta', 'Adrián',
    ];
    const bios = [
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
      'Teletrabajo en marketing, busco piso luminoso.',
      'Ciclista y senderista los fines de semana.',
    ];
    const interestPool = [
      'Música', 'Cine', 'Deporte', 'Viajes', 'Cocinar',
      'Lectura', 'Senderismo', 'Fotografía', 'Yoga', 'Arte',
    ];
    const femalePortraits = [
      'photo-1494790108377-be9c29b29330',
      'photo-1438761681033-6461ffad8d80',
      'photo-1544005313-94ddf0286df2',
      'photo-1517841905240-472988babdf9',
      'photo-1531123897727-8f129e1688ce',
      'photo-1489424731084-a5d8b219a5bb',
    ];
    const malePortraits = [
      'photo-1507003211169-0a1dd7228f2d',
      'photo-1500648767791-00dcc994a43e',
      'photo-1472099645785-5658abf4ff4e',
      'photo-1506794778202-cad84cf45f1d',
      'photo-1560250097-0b93528c311a',
      'photo-1519085360753-af0119f7cbe7',
    ];
    const apartmentInteriors = [
      'photo-1522708323590-d24dbb6b0267',
      'photo-1502672260266-1c1ef2d93688',
      'photo-1560448204-e02f11c3d0e2',
      'photo-1493809842364-78817add7ffb',
      'photo-1554995207-c18c203602cb',
      'photo-1484154218962-a197022b5858',
    ];
    const img = (id: string) =>
      `https://images.unsplash.com/${id}?auto=format&fit=crop&w=800&q=80`;
    const rand = (arr: string[]) =>
      arr[Math.floor(Math.random() * arr.length)];

    // --- Create 12 profiles ---
    const createdIds: string[] = [];
    const batch = db.batch();
    const now = Date.now();
    for (let i = 0; i < 12; i++) {
      const ref = db.collection('profiles').doc();
      createdIds.push(ref.id);
      const gender = i % 2 === 0 ? 'female' : 'male';
      const age = 22 + (i % 15);
      const portraits = gender === 'female' ? femalePortraits : malePortraits;
      const portraitIdx = Math.floor(i / 2);
      const photos = [
        img(portraits[portraitIdx % portraits.length]),
        img(portraits[(portraitIdx + 3) % portraits.length]),
      ];
      const location = new GeoPoint(
        baseLat + (Math.random() - 0.5) * 0.04,
        baseLon + (Math.random() - 0.5) * 0.04,
      );
      const budget = Math.round(myBudget * (0.95 + Math.random() * 0.1));
      const interests = [...new Set([rand(interestPool), rand(interestPool)])];

      const data: Record<string, unknown> = {
        uid: ref.id,
        name: names[i],
        userType: candidateType,
        photoURL: photos[0],
        birthDate: admin.firestore.Timestamp.fromDate(
          new Date(new Date().getFullYear() - age, i % 12, 15),
        ),
        createdAt: fv.serverTimestamp(),
        isActive: true,
        isPremium: false,
        isVerified: false,
        isDemo: true,
        seedVersion: 2,
        banned: false,
        geohash: this.encodeGeohash(
          Math.round(location.latitude * 100) / 100,
          Math.round(location.longitude * 100) / 100,
        ),
        profile: {
          age,
          bio: bios[i],
          gender,
          interests,
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
      if (candidateType === 'landlord') {
        data.apartment = {
          title: 'Habitación luminosa en piso compartido',
          location: 'Zona centro',
          price: budget,
          description: 'Habitación exterior con escritorio, gastos incluidos.',
          photos: [
            img(apartmentInteriors[i % apartmentInteriors.length]),
            img(apartmentInteriors[(i + 2) % apartmentInteriors.length]),
          ],
        };
      }
      batch.set(ref, data);
    }
    await batch.commit();

    // --- 5 incoming likes (demo -> user) ---
    const likesBatch = db.batch();
    const likeCount = Math.min(5, createdIds.length);
    for (let i = 0; i < likeCount; i++) {
      likesBatch.set(
        db.collection('swipes').doc(`${createdIds[i]}_${firebaseUid}`),
        {
          swiperId: createdIds[i],
          swipedId: firebaseUid,
          isLike: true,
          isDemo: true,
          timestamp: fv.serverTimestamp(),
        },
      );
    }
    await likesBatch.commit();

    // --- 3 mutual matches + chats with two-way messages ---
    let messagesCreated = 0;
    const matchCount = Math.min(3, createdIds.length);
    const convo: string[][] = [
      [
        '¡Hola! Me ha encantado tu perfil 😊',
        '¿Buscas piso por alguna zona en concreto?',
        'Sí, por el centro. ¿Y tú tienes habitación libre?',
        'Tengo una habitación exterior muy luminosa, te la puedo enseñar cuando quieras',
      ],
      [
        '¡Hola! Parece que tenemos intereses en común',
        '¡Hola! Sí, he visto que también te gusta el senderismo',
        'Sí, salgo casi todos los fines de semana',
        '¡Genial! Cuando quieras hablamos de la convivencia',
      ],
      [
        'Hola, he visto tu anuncio y me interesa',
        '¡Hola! Me alegro, cuéntame un poco sobre ti',
        'Trabajo en remoto, soy ordenado y tranquilo',
        'Perfecto, es justo el ambiente que buscamos en casa',
      ],
    ];
    for (let i = 0; i < matchCount; i++) {
      const demoId = createdIds[i];
      const pairId =
        firebaseUid < demoId
          ? `${firebaseUid}_${demoId}`
          : `${demoId}_${firebaseUid}`;

      await db
        .collection('swipes')
        .doc(`${firebaseUid}_${demoId}`)
        .set({
          swiperId: firebaseUid,
          swipedId: demoId,
          isLike: true,
          isDemo: true,
          timestamp: fv.serverTimestamp(),
        });

      const msgs = convo[i % convo.length];
      const lastMsg = msgs[msgs.length - 1];
      const lastTs = admin.firestore.Timestamp.fromMillis(
        now - i * 3600000 - 300000,
      );

      const pairBatch = db.batch();
      pairBatch.set(db.collection('matches').doc(pairId), {
        users: [firebaseUid, demoId],
        timestamp: fv.serverTimestamp(),
        lastMessage: lastMsg,
        lastMessageTimestamp: lastTs,
        unreadCount: { [firebaseUid]: 1, [demoId]: 0 },
      });
      pairBatch.set(db.collection('chats').doc(pairId), {
        participants: [firebaseUid, demoId],
        lastMessage: lastMsg,
        lastMessageTimestamp: lastTs,
        lastMessageSender: demoId,
        createdAt: fv.serverTimestamp(),
        unreadCounts: { [firebaseUid]: 1, [demoId]: 0 },
      });
      await pairBatch.commit();

      const msgBatch = db.batch();
      msgs.forEach((text, j) => {
        const fromDemo = j % 2 === 0;
        msgBatch.set(db.collection('chats').doc(pairId).collection('messages').doc(), {
          senderId: fromDemo ? demoId : firebaseUid,
          receiverId: fromDemo ? firebaseUid : demoId,
          message: text,
          imageUrl: null,
          timestamp: admin.firestore.Timestamp.fromMillis(
            now - i * 3600000 - (msgs.length - j) * 120000,
          ),
          read: !fromDemo,
        });
      });
      await msgBatch.commit();
      messagesCreated += msgs.length;
    }

    this.logger.log(
      `Demo seed uid=${firebaseUid} profiles=${createdIds.length} likes=${likeCount} matches=${matchCount} msgs=${messagesCreated}`,
    );
    return {
      profiles: createdIds.length,
      likes: likeCount,
      matches: matchCount,
      messages: messagesCreated,
    };
  }

  /**
   * Records a swipe on behalf of the caller and, on a mutual like,
   * creates the match + chat documents. Mirrors the client-side
   * MatchingService logic but runs with the Admin SDK, so it cannot
   * be rejected by Firestore rules.
   */
  async recordSwipe(
    firebaseUid: string,
    swipedId: string,
    isLike: boolean,
    isSuperLike = false,
  ): Promise<{ matched: boolean }> {
    if (!swipedId || swipedId === firebaseUid) {
      throw new BadRequestException('Invalid swipedId');
    }
    const db = admin.firestore();
    const fv = admin.firestore.FieldValue;

    await db
      .collection('swipes')
      .doc(`${firebaseUid}_${swipedId}`)
      .set({
        swiperId: firebaseUid,
        swipedId,
        isLike,
        ...(isSuperLike ? { isSuperLike: true } : {}),
        timestamp: fv.serverTimestamp(),
      });

    if (!isLike) return { matched: false };

    const mutual = await db
      .collection('swipes')
      .doc(`${swipedId}_${firebaseUid}`)
      .get();
    const mutualData = mutual.data();
    if (!mutual.exists || mutualData?.isLike !== true) {
      return { matched: false };
    }

    const pairId =
      firebaseUid < swipedId
        ? `${firebaseUid}_${swipedId}`
        : `${swipedId}_${firebaseUid}`;
    const batch = db.batch();
    batch.set(
      db.collection('matches').doc(pairId),
      {
        users: [firebaseUid, swipedId],
        timestamp: fv.serverTimestamp(),
        lastMessage: null,
        unreadCount: { [firebaseUid]: 0, [swipedId]: 0 },
      },
      { merge: true },
    );
    batch.set(
      db.collection('chats').doc(pairId),
      {
        participants: [firebaseUid, swipedId],
        lastMessage: null,
        lastMessageTimestamp: null,
        createdAt: fv.serverTimestamp(),
      },
      { merge: true },
    );
    await batch.commit();

    this.logger.log(
      `Swipe ${firebaseUid} -> ${swipedId} like=${isLike} matched=true`,
    );
    return { matched: true };
  }

  /** Minimal geohash encoder (mirrors the client's GeoHash utility). */
  private encodeGeohash(
    latitude: number,
    longitude: number,
    precision = 6,
  ): string {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    const latRange = [-90, 90];
    const lonRange = [-180, 180];
    let out = '';
    let bit = 0;
    let ch = 0;
    let even = true;
    while (out.length < precision) {
      if (even) {
        const mid = (lonRange[0] + lonRange[1]) / 2;
        if (longitude >= mid) {
          ch |= 1 << (4 - bit);
          lonRange[0] = mid;
        } else {
          lonRange[1] = mid;
        }
      } else {
        const mid = (latRange[0] + latRange[1]) / 2;
        if (latitude >= mid) {
          ch |= 1 << (4 - bit);
          latRange[0] = mid;
        } else {
          latRange[1] = mid;
        }
      }
      even = !even;
      if (bit < 4) {
        bit++;
      } else {
        out += base32[ch];
        bit = 0;
        ch = 0;
      }
    }
    return out;
  }
}
