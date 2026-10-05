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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var PaymentsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentsService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const crypto_1 = require("crypto");
const stripe_1 = __importDefault(require("stripe"));
const firebase_config_1 = require("../../common/config/firebase.config");
const mail_service_1 = require("../mail/mail.service");
const user_entity_1 = require("../users/entities/user.entity");
const payment_entity_1 = require("../admin/entities/payment.entity");
const subscription_entity_1 = require("../premium/entities/subscription.entity");
const RECEIPT_CATALOG = {
    premium_monthly: {
        name: 'Premium Mensual',
        description: 'Acceso premium por 30 dias',
        amountCents: 999,
    },
    premium_annual: {
        name: 'Premium Anual',
        description: 'Acceso premium por 365 dias',
        amountCents: 7999,
    },
    boost: {
        name: 'Boost',
        description: 'Tu perfil aparece primero durante 30 minutos',
        amountCents: 199,
    },
    super_like: {
        name: 'Super Like',
        description: 'Notificacion especial al otro usuario',
        amountCents: 99,
    },
    premium_verification: {
        name: 'Verificacion Premium',
        description: 'Revision manual y sello de confianza',
        amountCents: 299,
    },
    highlight_listing: {
        name: 'Destacar anuncio',
        description: 'Tu anuncio destacado durante 24 horas',
        amountCents: 399,
    },
};
let PaymentsService = PaymentsService_1 = class PaymentsService {
    onModuleInit() {
        void this._sweepExpiredSubscriptions();
        this._expiryTimer = setInterval(() => void this._sweepExpiredSubscriptions(), 60 * 60 * 1000);
        this._expiryTimer.unref();
    }
    onModuleDestroy() {
        if (this._expiryTimer)
            clearInterval(this._expiryTimer);
    }
    async _sweepExpiredSubscriptions() {
        try {
            const db = firebase_config_1.admin.firestore();
            const snap = await db
                .collection('subscriptions')
                .where('isActive', '==', true)
                .where('endDate', '<', Date.now())
                .limit(500)
                .get();
            if (snap.empty)
                return;
            const batch = db.batch();
            for (const doc of snap.docs) {
                batch.set(doc.ref, { isActive: false, autoRenew: false }, { merge: true });
                batch.set(db.collection('users').doc(doc.id), {
                    isPremium: false,
                    planId: 'basic',
                    subscription: { status: 'expired' },
                }, { merge: true });
            }
            await batch.commit();
            this.logger.log(`Expired ${snap.size} premium subscription(s) revoked`);
            await this.subscriptionRepository
                .createQueryBuilder()
                .update(subscription_entity_1.Subscription)
                .set({ isActive: false, autoRenew: false })
                .where('isActive = true AND endDate < :now', { now: new Date() })
                .execute();
        }
        catch (e) {
            this.logger.warn(`Premium expiry sweep failed: ${e}`);
        }
    }
    constructor(configService, mailService, userRepository, paymentRepository, subscriptionRepository) {
        this.configService = configService;
        this.mailService = mailService;
        this.userRepository = userRepository;
        this.paymentRepository = paymentRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.logger = new common_1.Logger(PaymentsService_1.name);
        this._expiryTimer = null;
        const secretKey = this.configService.get('STRIPE_SECRET_KEY');
        if (!secretKey || secretKey.includes('YOUR_SECRET_KEY')) {
            throw new Error('STRIPE_SECRET_KEY is not configured');
        }
        this.stripe = new stripe_1.default(secretKey, { apiVersion: '2024-06-20' });
        this.destinationBankAccount = this.configService.get('STRIPE_DESTINATION_BANK_ACCOUNT') || undefined;
    }
    async createCustomer(dto) {
        return this.stripe.customers.create({
            email: dto.email,
            name: dto.name,
        });
    }
    async createPaymentIntent(firebaseUid, dto) {
        const planId = dto.planId.replace(/_(us|gb|mx)$/i, '');
        const catalog = RECEIPT_CATALOG[dto.planId] ?? RECEIPT_CATALOG[planId];
        if (!catalog) {
            throw new common_1.BadRequestException(`Unknown plan: ${dto.planId}`);
        }
        const params = {
            amount: catalog.amountCents,
            currency: 'eur',
            customer: dto.customerId,
            metadata: {
                firebase_uid: firebaseUid,
                plan_id: dto.planId,
            },
            automatic_payment_methods: { enabled: true, allow_redirects: 'never' },
        };
        if (this.destinationBankAccount) {
            params.transfer_data = { destination: this.destinationBankAccount };
        }
        return this.stripe.paymentIntents.create(params);
    }
    async setupSubscription(firebaseUid, dto) {
        return this.stripe.subscriptions.create({
            customer: dto.customerId,
            items: [{ price: dto.priceId }],
            default_payment_method: dto.paymentMethodId,
            metadata: {
                firebase_uid: firebaseUid,
            },
            transfer_data: this.destinationBankAccount
                ? { destination: this.destinationBankAccount }
                : undefined,
        });
    }
    async cancelSubscription(subscriptionId) {
        return this.stripe.subscriptions.update(subscriptionId, {
            cancel_at_period_end: true,
        });
    }
    async getCustomerTransactions(customerId, limit = 10) {
        return this.stripe.charges.list({
            customer: customerId,
            limit,
        });
    }
    async sendPurchaseReceipt(firebaseUid, tokenEmail, dto) {
        const planId = dto.productId.replace(/_(us|gb|mx)$/i, '');
        const catalog = RECEIPT_CATALOG[dto.productId] ?? RECEIPT_CATALOG[planId];
        const amountCents = dto.amountCents ?? catalog?.amountCents ?? 0;
        const currency = (dto.currency || 'EUR').toUpperCase();
        const productName = dto.productName || catalog?.name || planId || dto.productId;
        let user = await this.userRepository.findOne({ where: { firebaseUid } });
        if (!user && tokenEmail) {
            user = await this.userRepository.save(this.userRepository.create({ firebaseUid, email: tokenEmail }));
        }
        const email = user?.email || tokenEmail;
        const provider = dto.platform === 'ios' ? 'apple_iap' : dto.platform === 'android' ? 'google_iap' : 'iap';
        const existing = await this.paymentRepository.findOne({
            where: { providerPaymentId: dto.transactionId },
        });
        if (existing) {
            return { sent: false, alreadyRecorded: true, invoiceNumber: null };
        }
        const invoiceNumber = this.buildInvoiceNumber(dto.transactionId);
        await this.paymentRepository.save({
            userId: user?.id ?? null,
            amount: amountCents,
            currency,
            status: 'succeeded',
            provider,
            providerPaymentId: dto.transactionId,
            planType: planId || dto.productId,
            metadata: {
                productId: dto.productId,
                platform: dto.platform ?? null,
                invoiceNumber,
            },
        });
        let sent = false;
        if (email) {
            sent = await this.mailService.sendPurchaseReceipt({
                to: email,
                customerName: user?.displayName,
                invoiceNumber,
                purchaseDate: new Date(),
                productName,
                productDescription: catalog?.description,
                amountCents,
                currency,
                platform: dto.platform,
                transactionId: dto.transactionId,
            });
            if (!sent) {
                this.logger.warn(`No se pudo enviar la factura ${invoiceNumber} a ${email}`);
            }
        }
        else {
            this.logger.warn(`Compra ${dto.transactionId} sin email asociado; factura ${invoiceNumber} no enviada`);
        }
        return { sent, alreadyRecorded: false, invoiceNumber };
    }
    buildInvoiceNumber(transactionId) {
        const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
        const suffix = transactionId.replace(/[^A-Za-z0-9]/g, '').slice(-6).toUpperCase() || '000000';
        return `RMM-${date}-${suffix}`;
    }
    async handleWebhook(payload, signature) {
        if (!signature) {
            throw new Error('Missing stripe-signature header');
        }
        const webhookSecret = this.configService.get('STRIPE_WEBHOOK_SECRET');
        if (!webhookSecret) {
            throw new Error('STRIPE_WEBHOOK_SECRET not configured');
        }
        const event = this.stripe.webhooks.constructEvent(payload, signature, webhookSecret);
        switch (event.type) {
            case 'payment_intent.succeeded':
                await this._handlePaymentIntentSucceeded(event.data.object);
                break;
            case 'payment_intent.payment_failed':
                await this._handlePaymentIntentFailed(event.data.object);
                break;
            case 'invoice.payment_succeeded':
                await this._handleInvoicePaymentSucceeded(event.data.object);
                break;
            case 'customer.subscription.deleted':
                await this._handleSubscriptionDeleted(event.data.object);
                break;
        }
        return { received: true };
    }
    async _getUserFromMetadata(firebaseUid) {
        if (!firebaseUid)
            return null;
        return this.userRepository.findOne({ where: { firebaseUid } });
    }
    async _handlePaymentIntentSucceeded(paymentIntent) {
        const user = await this._getUserFromMetadata(paymentIntent.metadata?.firebase_uid);
        if (!user)
            return;
        await this.paymentRepository.save({
            userId: user.id,
            amount: paymentIntent.amount,
            currency: paymentIntent.currency.toUpperCase(),
            status: 'succeeded',
            provider: 'stripe',
            providerPaymentId: paymentIntent.id,
            planType: paymentIntent.metadata?.plan_id,
            metadata: paymentIntent.metadata || {},
        });
    }
    async _handlePaymentIntentFailed(paymentIntent) {
        const user = await this._getUserFromMetadata(paymentIntent.metadata?.firebase_uid);
        if (!user)
            return;
        await this.paymentRepository.save({
            userId: user.id,
            amount: paymentIntent.amount,
            currency: paymentIntent.currency?.toUpperCase() || 'EUR',
            status: 'failed',
            provider: 'stripe',
            providerPaymentId: paymentIntent.id,
            planType: paymentIntent.metadata?.plan_id,
            metadata: paymentIntent.metadata || {},
        });
    }
    async _handleInvoicePaymentSucceeded(invoice) {
        const subscriptionId = invoice.subscription;
        if (!subscriptionId)
            return;
        const subscription = await this.stripe.subscriptions.retrieve(subscriptionId);
        const user = await this._getUserFromMetadata(subscription.metadata?.firebase_uid);
        if (!user)
            return;
        const periodEnd = new Date((invoice.period_end || 0) * 1000);
        const periodStart = new Date((invoice.period_start || 0) * 1000);
        let sub = await this.subscriptionRepository.findOne({
            where: { userId: user.id, planType: 'premium' },
        });
        if (!sub) {
            sub = this.subscriptionRepository.create({ userId: user.id, planType: 'premium' });
        }
        sub.startDate = periodStart;
        sub.endDate = periodEnd;
        sub.isActive = true;
        sub.autoRenew = !subscription.cancel_at_period_end;
        sub.paymentMethod = 'stripe';
        await this.subscriptionRepository.save(sub);
        user.isPremium = true;
        user.premiumExpiresAt = periodEnd;
        await this.userRepository.save(user);
        await this._writeFirestoreEntitlement(user.firebaseUid, periodEnd.getTime(), 'stripe');
    }
    async _handleSubscriptionDeleted(subscription) {
        const user = await this._getUserFromMetadata(subscription.metadata?.firebase_uid);
        if (!user)
            return;
        const sub = await this.subscriptionRepository.findOne({
            where: { userId: user.id, planType: 'premium' },
        });
        if (sub) {
            sub.isActive = false;
            sub.autoRenew = false;
            await this.subscriptionRepository.save(sub);
        }
        user.isPremium = false;
        user.premiumExpiresAt = null;
        await this.userRepository.save(user);
        await this._revokeFirestoreEntitlement(user.firebaseUid);
    }
    async verifyIapPurchase(firebaseUid, dto) {
        const planId = dto.productId.replace(/_(us|gb|mx)$/i, '');
        const catalog = RECEIPT_CATALOG[dto.productId] ?? RECEIPT_CATALOG[planId];
        if (planId === 'free_trial') {
            return this._grantFreeTrial(firebaseUid);
        }
        if (!catalog) {
            throw new common_1.BadRequestException(`Unknown product: ${dto.productId}`);
        }
        const existing = await this.paymentRepository.findOne({
            where: { providerPaymentId: dto.transactionId },
        });
        if (existing && existing.metadata?.grantedAt) {
            return { verified: true, alreadyGranted: true };
        }
        let verifiedBy = 'unverified';
        let expiryMs = null;
        if (dto.platform === 'ios') {
            const r = await this._verifyAppleReceipt(dto.verificationData, planId);
            verifiedBy = r.verified ? 'apple' : 'unverified';
            expiryMs = r.expiryMs;
        }
        else if (dto.platform === 'android') {
            const r = await this._verifyGooglePurchase(dto.verificationData, dto.productId, planId);
            verifiedBy = r.verified ? 'google' : 'unverified';
            expiryMs = r.expiryMs;
        }
        else {
            throw new common_1.BadRequestException(`Invalid platform: ${dto.platform}`);
        }
        await this._grantEntitlement(firebaseUid, planId, expiryMs, dto.transactionId, dto.platform);
        let user = await this.userRepository.findOne({ where: { firebaseUid } });
        if (!user) {
            user = await this.userRepository.save(this.userRepository.create({ firebaseUid }));
        }
        if (!existing) {
            await this.paymentRepository.save({
                userId: user.id,
                amount: catalog.amountCents,
                currency: 'EUR',
                status: 'succeeded',
                provider: dto.platform === 'ios' ? 'apple_iap' : 'google_iap',
                providerPaymentId: dto.transactionId,
                planType: planId,
                metadata: {
                    productId: dto.productId,
                    platform: dto.platform,
                    verifiedBy,
                    grantedAt: new Date().toISOString(),
                },
            });
        }
        this.logger.log(`IAP granted uid=${firebaseUid} product=${planId} tx=${dto.transactionId} verifiedBy=${verifiedBy}`);
        return { verified: true, verifiedBy, alreadyGranted: false };
    }
    async _grantFreeTrial(firebaseUid) {
        const db = firebase_config_1.admin.firestore();
        const userRef = db.collection('users').doc(firebaseUid);
        const granted = await db.runTransaction(async (tx) => {
            const snap = await tx.get(userRef);
            if (!snap.exists)
                return false;
            if (snap.get('hasUsedFreeTrial') === true)
                return false;
            const endMs = Date.now() + 7 * 24 * 3600 * 1000;
            tx.set(userRef, {
                hasUsedFreeTrial: true,
                isPremium: true,
                planId: 'premium',
                subscription: {
                    planId: 'free_trial',
                    planName: 'Prueba Gratis',
                    endDate: firebase_config_1.admin.firestore.Timestamp.fromMillis(endMs),
                    autoRenew: false,
                    status: 'trial',
                },
            }, { merge: true });
            tx.set(db.collection('subscriptions').doc(firebaseUid), {
                userId: firebaseUid,
                planId: 'premium',
                startDate: Date.now(),
                endDate: endMs,
                isActive: true,
                autoRenew: false,
                paymentMethod: 'free_trial',
            }, { merge: true });
            return true;
        });
        if (!granted) {
            throw new common_1.BadRequestException('Free trial already used');
        }
        return { verified: true, granted: 'free_trial' };
    }
    async _grantEntitlement(firebaseUid, planId, expiryMs, transactionId, platform) {
        const db = firebase_config_1.admin.firestore();
        const userRef = db.collection('users').doc(firebaseUid);
        const now = Date.now();
        switch (planId) {
            case 'premium_monthly':
            case 'premium_annual': {
                const days = planId === 'premium_annual' ? 365 : 30;
                const endMs = expiryMs ?? now + days * 86400000;
                await db.collection('subscriptions').doc(firebaseUid).set({
                    userId: firebaseUid,
                    planId: 'premium',
                    startDate: now,
                    endDate: endMs,
                    isActive: true,
                    autoRenew: true,
                    paymentMethod: 'iap',
                    storeTransactionId: transactionId,
                    store: platform,
                }, { merge: true });
                await this._writeFirestoreEntitlement(firebaseUid, endMs, 'iap');
                break;
            }
            case 'boost': {
                const endMs = now + 30 * 60000;
                await userRef.collection('boosts').add({
                    durationMinutes: 30,
                    timestamp: firebase_config_1.admin.firestore.FieldValue.serverTimestamp(),
                    transactionId,
                });
                await userRef.set({
                    isBoosted: true,
                    boostEndTime: firebase_config_1.admin.firestore.Timestamp.fromMillis(endMs),
                }, { merge: true });
                break;
            }
            case 'super_like':
                await userRef.set({ superLikesAvailable: firebase_config_1.admin.firestore.FieldValue.increment(1) }, { merge: true });
                break;
            case 'premium_verification':
                await userRef.set({
                    isVerified: true,
                    'verification.isPremiumVerified': true,
                    'verification.premiumVerifiedAt': firebase_config_1.admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });
                break;
            case 'highlight_listing': {
                const until = now + 24 * 3600 * 1000;
                await userRef.set({
                    isListingHighlighted: true,
                    listingHighlightedUntil: firebase_config_1.admin.firestore.Timestamp.fromMillis(until),
                }, { merge: true });
                break;
            }
            default:
                throw new common_1.BadRequestException(`Cannot grant product: ${planId}`);
        }
    }
    async _writeFirestoreEntitlement(firebaseUid, endMs, source) {
        try {
            await firebase_config_1.admin.firestore().collection('users').doc(firebaseUid).set({
                isPremium: true,
                planId: 'premium',
                subscription: {
                    status: 'active',
                    autoRenew: true,
                    source,
                    endDate: firebase_config_1.admin.firestore.Timestamp.fromMillis(endMs),
                },
            }, { merge: true });
        }
        catch (e) {
            this.logger.warn(`Firestore entitlement write failed for ${firebaseUid}: ${e}`);
        }
    }
    async _revokeFirestoreEntitlement(firebaseUid) {
        try {
            const db = firebase_config_1.admin.firestore();
            await db.collection('users').doc(firebaseUid).set({
                isPremium: false,
                planId: 'basic',
                subscription: {
                    status: 'expired',
                },
            }, { merge: true });
            await db.collection('subscriptions').doc(firebaseUid).set({ isActive: false, autoRenew: false }, { merge: true });
        }
        catch (e) {
            this.logger.warn(`Firestore entitlement revoke failed for ${firebaseUid}: ${e}`);
        }
    }
    async _verifyAppleReceipt(receiptData, planId) {
        const secret = this.configService.get('APPLE_SHARED_SECRET');
        if (!secret) {
            this.logger.warn('APPLE_SHARED_SECRET not set — skipping Apple receipt validation');
            return { verified: false, expiryMs: null };
        }
        if (!receiptData) {
            throw new common_1.BadRequestException('Missing receipt data');
        }
        const verify = async (url) => {
            const res = await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ 'receipt-data': receiptData, password: secret }),
            });
            return res.json();
        };
        let body = await verify('https://buy.itunes.apple.com/verifyReceipt');
        if (body.status === 21007) {
            body = await verify('https://sandbox.itunes.apple.com/verifyReceipt');
        }
        if (body.status !== 0) {
            throw new common_1.BadRequestException(`Apple receipt invalid (status=${body.status})`);
        }
        const isSubscription = planId === 'premium_monthly' || planId === 'premium_annual';
        const items = body.latest_receipt_info ?? body.receipt?.in_app ?? [];
        const match = items
            .filter((i) => i.product_id === planId || i.product_id?.startsWith(planId))
            .sort((a, b) => Number(b.expires_date_ms ?? 0) - Number(a.expires_date_ms ?? 0))[0];
        if (!match) {
            throw new common_1.BadRequestException('Product not found in receipt');
        }
        if (isSubscription) {
            const expiryMs = Number(match.expires_date_ms ?? 0);
            if (expiryMs <= Date.now()) {
                throw new common_1.BadRequestException('Subscription expired');
            }
            return { verified: true, expiryMs };
        }
        return { verified: true, expiryMs: null };
    }
    async _verifyGooglePurchase(purchaseToken, productId, planId) {
        const saJson = this.configService.get('GOOGLE_PLAY_SA_JSON');
        const packageName = this.configService.get('GOOGLE_PLAY_PACKAGE_NAME');
        if (!saJson || !packageName) {
            this.logger.warn('GOOGLE_PLAY_SA_JSON/GOOGLE_PLAY_PACKAGE_NAME not set — skipping Google verification');
            return { verified: false, expiryMs: null };
        }
        if (!purchaseToken) {
            throw new common_1.BadRequestException('Missing purchase token');
        }
        const sa = JSON.parse(saJson);
        const token = await this._googleAccessToken(sa);
        const base = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases`;
        const isSubscription = planId === 'premium_monthly' || planId === 'premium_annual';
        const url = isSubscription
            ? `${base}/subscriptions/${productId}/tokens/${purchaseToken}`
            : `${base}/products/${productId}/tokens/${purchaseToken}`;
        const res = await fetch(url, {
            headers: { Authorization: `Bearer ${token}` },
        });
        if (!res.ok) {
            throw new common_1.BadRequestException(`Google purchase invalid (HTTP ${res.status})`);
        }
        const body = (await res.json());
        if (isSubscription) {
            const expiryMs = Number(body.expiryTimeMillis ?? 0);
            if (expiryMs <= Date.now()) {
                throw new common_1.BadRequestException('Subscription expired');
            }
            return { verified: true, expiryMs };
        }
        if (body.purchaseState !== 0) {
            throw new common_1.BadRequestException('Purchase not completed');
        }
        return { verified: true, expiryMs: null };
    }
    async _googleAccessToken(sa) {
        const now = Math.floor(Date.now() / 1000);
        const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
        const unsigned = `${b64({ alg: 'RS256', typ: 'JWT' })}.` +
            `${b64({
                iss: sa.client_email,
                scope: 'https://www.googleapis.com/auth/androidpublisher',
                aud: 'https://oauth2.googleapis.com/token',
                iat: now,
                exp: now + 3600,
            })}`;
        const sign = (0, crypto_1.createSign)('RSA-SHA256');
        sign.update(unsigned);
        const jwt = `${unsigned}.${sign.sign(sa.private_key, 'base64url')}`;
        const res = await fetch('https://oauth2.googleapis.com/token', {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({
                grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                assertion: jwt,
            }),
        });
        const body = (await res.json());
        if (!body.access_token) {
            throw new common_1.ServiceUnavailableException('Google auth failed');
        }
        return body.access_token;
    }
};
exports.PaymentsService = PaymentsService;
exports.PaymentsService = PaymentsService = PaymentsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(2, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(3, (0, typeorm_1.InjectRepository)(payment_entity_1.Payment)),
    __param(4, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __metadata("design:paramtypes", [config_1.ConfigService,
        mail_service_1.MailService,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], PaymentsService);
//# sourceMappingURL=payments.service.js.map