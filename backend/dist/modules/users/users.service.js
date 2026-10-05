"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var UsersService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsersService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const firebase_config_1 = require("../../common/config/firebase.config");
const user_entity_1 = require("./entities/user.entity");
const consent_log_entity_1 = require("./entities/consent-log.entity");
const data_request_entity_1 = require("./entities/data-request.entity");
let UsersService = UsersService_1 = class UsersService {
    constructor(usersRepository, consentLogRepository, dataRequestRepository) {
        this.usersRepository = usersRepository;
        this.consentLogRepository = consentLogRepository;
        this.dataRequestRepository = dataRequestRepository;
        this.logger = new common_1.Logger(UsersService_1.name);
    }
    async findByFirebaseUid(firebaseUid) {
        return this.usersRepository.findOne({ where: { firebaseUid } });
    }
    async create(firebaseUid, email) {
        const user = this.usersRepository.create({
            firebaseUid,
            email,
        });
        return this.usersRepository.save(user);
    }
    async logConsent(firebaseUid, consentType, accepted, metadata) {
        const user = await this.findByFirebaseUid(firebaseUid);
        if (!user)
            throw new common_1.NotFoundException('User not found');
        const fieldMap = {
            terms: 'acceptedTermsAt',
            privacy: 'acceptedPrivacyAt',
            cookies: 'acceptedCookiesAt',
        };
        const field = fieldMap[consentType];
        if (field) {
            user[field] = accepted ? new Date() : null;
        }
        const consent = (user.consent || {});
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
    async exportData(firebaseUid) {
        const user = await this.findByFirebaseUid(firebaseUid);
        if (!user)
            throw new common_1.NotFoundException('User not found');
        const consents = await this.consentLogRepository.find({
            where: { firebaseUid },
            order: { createdAt: 'DESC' },
        });
        await this.dataRequestRepository.save(this.dataRequestRepository.create({
            userId: user.id,
            firebaseUid,
            requestType: 'export',
            status: 'completed',
            payload: { userEmail: user.email },
            completedAt: new Date(),
        }));
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
    async deleteUser(firebaseUid) {
        const user = await this.findByFirebaseUid(firebaseUid);
        if (!user)
            throw new common_1.NotFoundException('User not found');
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
    async deleteFirebaseData(firebaseUid) {
        const db = firebase_config_1.admin.firestore();
        const errors = [];
        const safe = async (label, fn) => {
            try {
                await fn();
            }
            catch (e) {
                const message = e instanceof Error ? e.message : String(e);
                errors.push(`${label}: ${message}`);
                this.logger.warn(`deleteFirebaseData ${label} failed: ${message}`);
            }
        };
        const deleteWhere = async (collection, field, op, value, recursive = false) => {
            const snap = await db
                .collection(collection)
                .where(field, op, value)
                .get();
            if (snap.empty)
                return;
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
            if (count > 0)
                await batch.commit();
        };
        await safe('users doc + subcollections', () => db.recursiveDelete(db.collection('users').doc(firebaseUid)));
        await safe('profiles doc', () => db.recursiveDelete(db.collection('profiles').doc(firebaseUid)));
        await safe('subscriptions doc', () => db.collection('subscriptions').doc(firebaseUid).delete());
        await safe('admins doc', () => db.collection('admins').doc(firebaseUid).delete());
        await safe('swipes as swiper', () => deleteWhere('swipes', 'swiperId', '==', firebaseUid));
        await safe('swipes as swiped', () => deleteWhere('swipes', 'swipedId', '==', firebaseUid));
        await safe('matches', () => deleteWhere('matches', 'users', 'array-contains', firebaseUid));
        await safe('chats', () => deleteWhere('chats', 'participants', 'array-contains', firebaseUid, true));
        await safe('conversations', () => deleteWhere('conversations', 'participants', 'array-contains', firebaseUid, true));
        await safe('blocked_users (blocker)', () => deleteWhere('blocked_users', 'blockerId', '==', firebaseUid));
        await safe('blocked_users (blocked)', () => deleteWhere('blocked_users', 'blockedId', '==', firebaseUid));
        await safe('listings', () => deleteWhere('listings', 'ownerId', '==', firebaseUid));
        await safe('verification_requests', () => deleteWhere('verification_requests', 'userId', '==', firebaseUid));
        await safe('reports', () => deleteWhere('reports', 'reporterId', '==', firebaseUid));
        await safe('moderation_queue', () => deleteWhere('moderation_queue', 'reporterId', '==', firebaseUid));
        await safe('referrals (referrer)', () => deleteWhere('referrals', 'referrerId', '==', firebaseUid));
        await safe('referrals (referred)', () => deleteWhere('referrals', 'referredId', '==', firebaseUid));
        await safe('feedback', () => deleteWhere('feedback', 'userId', '==', firebaseUid));
        await safe('support_messages', () => deleteWhere('support_messages', 'userId', '==', firebaseUid));
        await safe('purchases', () => deleteWhere('purchases', 'userId', '==', firebaseUid));
        await safe('boosts', () => deleteWhere('boosts', 'userId', '==', firebaseUid));
        await safe('transactions', () => deleteWhere('transactions', 'userId', '==', firebaseUid));
        await safe('user_registrations', () => deleteWhere('user_registrations', 'userId', '==', firebaseUid));
        await safe('subscription_events', () => deleteWhere('subscription_events', 'userId', '==', firebaseUid));
        await safe('analytics_events', () => deleteWhere('analytics_events', 'userId', '==', firebaseUid));
        const bucketName = process.env.FIREBASE_STORAGE_BUCKET ||
            `${process.env.FIREBASE_PROJECT_ID}.firebasestorage.app`;
        await safe('storage', async () => {
            const bucket = firebase_config_1.admin.storage().bucket(bucketName);
            for (const prefix of [`users/${firebaseUid}/`, `user_photos/${firebaseUid}/`]) {
                await bucket.deleteFiles({ prefix });
            }
        });
        await safe('auth user', () => firebase_config_1.admin.auth().deleteUser(firebaseUid));
        if (errors.length > 0) {
            this.logger.warn(`Partial cleanup for uid=${firebaseUid}: ${errors.join(' | ')}`);
        }
        else {
            this.logger.log(`Firebase data fully deleted for uid=${firebaseUid}`);
        }
    }
    async claimReferralRewards(firebaseUid) {
        const db = firebase_config_1.admin.firestore();
        const pending = await db
            .collection('referrals')
            .where('referrerId', '==', firebaseUid)
            .where('status', '==', 'completed')
            .limit(100)
            .get();
        const unrewarded = pending.docs.filter((d) => d.data().rewarded !== true);
        if (unrewarded.length === 0) {
            return { granted: 0 };
        }
        const likesPerReferral = 5;
        const totalLikes = unrewarded.length * likesPerReferral;
        await db.collection('users').doc(firebaseUid).set({ freeLikes: firebase_config_1.admin.firestore.FieldValue.increment(totalLikes) }, { merge: true });
        const batch = db.batch();
        for (const doc of unrewarded) {
            batch.update(doc.ref, {
                rewarded: true,
                rewardedAt: firebase_config_1.admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        await batch.commit();
        this.logger.log(`Referral rewards granted uid=${firebaseUid} count=${unrewarded.length} likes=${totalLikes}`);
        return { granted: unrewarded.length, freeLikes: totalLikes };
    }
    async seedDemoData(firebaseUid) {
        const db = firebase_config_1.admin.firestore();
        const fv = firebase_config_1.admin.firestore.FieldValue;
        const GeoPoint = firebase_config_1.admin.firestore.GeoPoint;
        const meRef = db.collection('users').doc(firebaseUid);
        const meSnap = await meRef.get();
        const me = meSnap.data() ?? {};
        if (!me.preferences || typeof me.preferences !== 'object') {
            await meRef.set({
                preferences: {
                    ageRange: [18, 40],
                    gender: 'all',
                    budget: 650,
                    maxDistance: 50,
                    location: new GeoPoint(40.4168, -3.7038),
                },
            }, { merge: true });
            me.preferences = {
                ageRange: [18, 40],
                gender: 'all',
                budget: 650,
                maxDistance: 50,
                location: new GeoPoint(40.4168, -3.7038),
            };
        }
        const myType = me.userType ?? 'tenant';
        const candidateType = myType === 'landlord' ? 'tenant' : 'landlord';
        const myLoc = me.preferences?.location;
        const baseLat = myLoc?.latitude ?? 40.4168;
        const baseLon = myLoc?.longitude ?? -3.7038;
        const myBudget = typeof me.preferences?.budget === 'number' ? me.preferences.budget : 650;
        const demoSnap = await db
            .collection('profiles')
            .where('isDemo', '==', true)
            .get();
        const demoIds = new Set(demoSnap.docs.map((d) => d.id));
        if (demoIds.size > 0) {
            const purge = db.batch();
            for (const d of demoSnap.docs)
                purge.delete(d.ref);
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
                const users = d.data().users ?? [];
                if (users.some((u) => demoIds.has(u))) {
                    purge.delete(d.ref);
                    purge.delete(db.collection('chats').doc(d.id));
                }
            }
            await purge.commit();
        }
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
        const img = (id) => `https://images.unsplash.com/${id}?auto=format&fit=crop&w=800&q=80`;
        const rand = (arr) => arr[Math.floor(Math.random() * arr.length)];
        const createdIds = [];
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
            const location = new GeoPoint(baseLat + (Math.random() - 0.5) * 0.04, baseLon + (Math.random() - 0.5) * 0.04);
            const budget = Math.round(myBudget * (0.95 + Math.random() * 0.1));
            const interests = [...new Set([rand(interestPool), rand(interestPool)])];
            const data = {
                uid: ref.id,
                name: names[i],
                userType: candidateType,
                photoURL: photos[0],
                birthDate: firebase_config_1.admin.firestore.Timestamp.fromDate(new Date(new Date().getFullYear() - age, i % 12, 15)),
                createdAt: fv.serverTimestamp(),
                isActive: true,
                isPremium: false,
                isVerified: false,
                isDemo: true,
                seedVersion: 2,
                banned: false,
                geohash: this.encodeGeohash(Math.round(location.latitude * 100) / 100, Math.round(location.longitude * 100) / 100),
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
        const likesBatch = db.batch();
        const likeCount = Math.min(5, createdIds.length);
        for (let i = 0; i < likeCount; i++) {
            likesBatch.set(db.collection('swipes').doc(`${createdIds[i]}_${firebaseUid}`), {
                swiperId: createdIds[i],
                swipedId: firebaseUid,
                isLike: true,
                isDemo: true,
                timestamp: fv.serverTimestamp(),
            });
        }
        await likesBatch.commit();
        let messagesCreated = 0;
        const matchCount = Math.min(3, createdIds.length);
        const convo = [
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
            const pairId = firebaseUid < demoId
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
            const lastTs = firebase_config_1.admin.firestore.Timestamp.fromMillis(now - i * 3600000 - 300000);
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
                    timestamp: firebase_config_1.admin.firestore.Timestamp.fromMillis(now - i * 3600000 - (msgs.length - j) * 120000),
                    read: !fromDemo,
                });
            });
            await msgBatch.commit();
            messagesCreated += msgs.length;
        }
        this.logger.log(`Demo seed uid=${firebaseUid} profiles=${createdIds.length} likes=${likeCount} matches=${matchCount} msgs=${messagesCreated}`);
        return {
            profiles: createdIds.length,
            likes: likeCount,
            matches: matchCount,
            messages: messagesCreated,
        };
    }
    encodeGeohash(latitude, longitude, precision = 6) {
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
                }
                else {
                    lonRange[1] = mid;
                }
            }
            else {
                const mid = (latRange[0] + latRange[1]) / 2;
                if (latitude >= mid) {
                    ch |= 1 << (4 - bit);
                    latRange[0] = mid;
                }
                else {
                    latRange[1] = mid;
                }
            }
            even = !even;
            if (bit < 4) {
                bit++;
            }
            else {
                out += base32[ch];
                bit = 0;
                ch = 0;
            }
        }
        return out;
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = UsersService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(1, (0, typeorm_1.InjectRepository)(consent_log_entity_1.ConsentLog)),
    __param(2, (0, typeorm_1.InjectRepository)(data_request_entity_1.DataRequest)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], UsersService);
//# sourceMappingURL=users.service.js.map