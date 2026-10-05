import { Injectable, BadRequestException, ForbiddenException, Logger, ServiceUnavailableException, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { createSign } from 'crypto';
import Stripe from 'stripe';
import { admin } from '../../common/config/firebase.config';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { SetupSubscriptionDto } from './dto/setup-subscription.dto';
import { SendReceiptDto } from './dto/send-receipt.dto';
import { VerifyIapDto } from './dto/verify-iap.dto';
import { MailService } from '../mail/mail.service';
import { User } from '../users/entities/user.entity';
import { Payment } from '../admin/entities/payment.entity';
import { Subscription } from '../premium/entities/subscription.entity';

const RECEIPT_CATALOG: Record<
  string,
  { name: string; description: string; amountCents: number }
> = {
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

@Injectable()
export class PaymentsService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PaymentsService.name);
  private readonly stripe: Stripe;
  private readonly destinationBankAccount: string | undefined;
  private _expiryTimer: NodeJS.Timeout | null = null;

  /** Hourly sweep that revokes expired premium entitlements in Firestore. */
  onModuleInit() {
    void this._sweepExpiredSubscriptions();
    this._expiryTimer = setInterval(
      () => void this._sweepExpiredSubscriptions(),
      60 * 60 * 1000,
    );
    this._expiryTimer.unref();
  }

  onModuleDestroy() {
    if (this._expiryTimer) clearInterval(this._expiryTimer);
  }

  /**
   * Finds subscriptions/{uid} docs that expired and revokes the premium
   * entitlement (isPremium=false + isActive=false). Grants without a revoke
   * path were the main remaining gap in the payment flow.
   */
  private async _sweepExpiredSubscriptions() {
    try {
      const db = admin.firestore();
      const snap = await db
        .collection('subscriptions')
        .where('isActive', '==', true)
        .where('endDate', '<', Date.now())
        .limit(500)
        .get();

      if (snap.empty) return;

      const batch = db.batch();
      for (const doc of snap.docs) {
        batch.set(doc.ref, { isActive: false, autoRenew: false }, { merge: true });
        batch.set(
          db.collection('users').doc(doc.id),
          {
            isPremium: false,
            planId: 'basic',
            subscription: { status: 'expired' },
          },
          { merge: true },
        );
      }
      await batch.commit();
      this.logger.log(`Expired ${snap.size} premium subscription(s) revoked`);

      // Also keep Postgres in sync (best-effort)
      await this.subscriptionRepository
        .createQueryBuilder()
        .update(Subscription)
        .set({ isActive: false, autoRenew: false })
        .where('isActive = true AND endDate < :now', { now: new Date() })
        .execute();
    } catch (e) {
      this.logger.warn(`Premium expiry sweep failed: ${e}`);
    }
  }

  constructor(
    private readonly configService: ConfigService,
    private readonly mailService: MailService,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
    @InjectRepository(Subscription)
    private readonly subscriptionRepository: Repository<Subscription>,
  ) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (!secretKey || secretKey.includes('YOUR_SECRET_KEY')) {
      throw new Error('STRIPE_SECRET_KEY is not configured');
    }
    this.stripe = new Stripe(secretKey, { apiVersion: '2024-06-20' });
    this.destinationBankAccount = this.configService.get<string>('STRIPE_DESTINATION_BANK_ACCOUNT') || undefined;
  }

  async createCustomer(dto: CreateCustomerDto) {
    return this.stripe.customers.create({
      email: dto.email,
      name: dto.name,
    });
  }

  async createPaymentIntent(firebaseUid: string, dto: CreatePaymentIntentDto) {
    // SECURITY: the amount is NEVER taken from the client. The server-side
    // catalog is the single source of truth for prices.
    const planId = dto.planId.replace(/_(us|gb|mx)$/i, '');
    const catalog = RECEIPT_CATALOG[dto.planId] ?? RECEIPT_CATALOG[planId];
    if (!catalog) {
      throw new BadRequestException(`Unknown plan: ${dto.planId}`);
    }

    const params: Stripe.PaymentIntentCreateParams = {
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

  async setupSubscription(firebaseUid: string, dto: SetupSubscriptionDto) {
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

  async cancelSubscription(firebaseUid: string, subscriptionId: string) {
    const subscription =
      await this.stripe.subscriptions.retrieve(subscriptionId);
    if (subscription.metadata?.firebase_uid !== firebaseUid) {
      throw new ForbiddenException('Subscription does not belong to this user');
    }
    return this.stripe.subscriptions.update(subscriptionId, {
      cancel_at_period_end: true,
    });
  }

  async getCustomerTransactions(customerId: string, limit = 10) {
    return this.stripe.charges.list({
      customer: customerId,
      limit,
    });
  }

  /**
   * Registra una compra IAP (App Store / Google Play) y envia la factura al
   * email del usuario. Las renovaciones/restauraciones de suscripciones se
   * deduplican por transactionId y no reenvian el email.
   */
  async sendPurchaseReceipt(firebaseUid: string, tokenEmail: string | undefined, dto: SendReceiptDto) {
    const planId = dto.productId.replace(/_(us|gb|mx)$/i, '');
    const catalog = RECEIPT_CATALOG[dto.productId] ?? RECEIPT_CATALOG[planId];

    const amountCents = dto.amountCents ?? catalog?.amountCents ?? 0;
    const currency = (dto.currency || 'EUR').toUpperCase();
    const productName = dto.productName || catalog?.name || planId || dto.productId;

    let user = await this.userRepository.findOne({ where: { firebaseUid } });
    if (!user && tokenEmail) {
      // El usuario puede no existir aun en esta BD si nunca se registro via API.
      user = await this.userRepository.save(
        this.userRepository.create({ firebaseUid, email: tokenEmail }),
      );
    }

    const email = user?.email || tokenEmail;

    const provider =
      dto.platform === 'ios' ? 'apple_iap' : dto.platform === 'android' ? 'google_iap' : 'iap';

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
    } else {
      this.logger.warn(
        `Compra ${dto.transactionId} sin email asociado; factura ${invoiceNumber} no enviada`,
      );
    }

    return { sent, alreadyRecorded: false, invoiceNumber };
  }

  /** RMM-YYYYMMDD-XXXXXX (derivado del transactionId, deterministico). */
  private buildInvoiceNumber(transactionId: string): string {
    const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const suffix = transactionId.replace(/[^A-Za-z0-9]/g, '').slice(-6).toUpperCase() || '000000';
    return `RMM-${date}-${suffix}`;
  }

  async handleWebhook(payload: Buffer, signature: string | undefined) {
    if (!signature) {
      throw new Error('Missing stripe-signature header');
    }

    const webhookSecret = this.configService.get<string>('STRIPE_WEBHOOK_SECRET');
    if (!webhookSecret) {
      throw new Error('STRIPE_WEBHOOK_SECRET not configured');
    }

    const event = this.stripe.webhooks.constructEvent(payload, signature, webhookSecret);

    switch (event.type) {
      case 'payment_intent.succeeded':
        await this._handlePaymentIntentSucceeded(event.data.object as Stripe.PaymentIntent);
        break;
      case 'payment_intent.payment_failed':
        await this._handlePaymentIntentFailed(event.data.object as Stripe.PaymentIntent);
        break;
      case 'invoice.payment_succeeded':
        await this._handleInvoicePaymentSucceeded(event.data.object as Stripe.Invoice);
        break;
      case 'customer.subscription.deleted':
        await this._handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
        break;
    }

    return { received: true };
  }

  private async _getUserFromMetadata(firebaseUid: string | undefined): Promise<User | null> {
    if (!firebaseUid) return null;
    return this.userRepository.findOne({ where: { firebaseUid } });
  }

  private async _handlePaymentIntentSucceeded(paymentIntent: Stripe.PaymentIntent) {
    const user = await this._getUserFromMetadata(paymentIntent.metadata?.firebase_uid);
    if (!user) return;

    // Idempotency: Stripe retries webhooks — skip already-recorded intents.
    const existing = await this.paymentRepository.findOne({
      where: { providerPaymentId: paymentIntent.id },
    });
    if (existing) return;

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

    // Deliver the product: without this a successful web/card payment was
    // recorded but never unlocked anything in the app.
    const planId = (paymentIntent.metadata?.plan_id || '').replace(
      /_(us|gb|mx)$/i,
      '',
    );
    if (RECEIPT_CATALOG[planId]) {
      const db = admin.firestore();
      const markerRef = db
        .collection('iap_grants')
        .doc(`${user.firebaseUid}_${paymentIntent.id}`);
      await db.runTransaction(async (tx) => {
        const marker = await tx.get(markerRef);
        if (marker.exists) return;
        await this._grantEntitlement(
          user.firebaseUid,
          planId,
          null,
          paymentIntent.id,
          'stripe',
          tx,
        );
        tx.create(markerRef, {
          uid: user.firebaseUid,
          transactionId: paymentIntent.id,
          planId,
          verifiedBy: 'stripe_webhook',
          grantedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
    }
  }

  private async _handlePaymentIntentFailed(paymentIntent: Stripe.PaymentIntent) {
    const user = await this._getUserFromMetadata(paymentIntent.metadata?.firebase_uid);
    if (!user) return;

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

  private async _handleInvoicePaymentSucceeded(invoice: Stripe.Invoice) {
    const subscriptionId = invoice.subscription as string;
    if (!subscriptionId) return;

    const subscription = await this.stripe.subscriptions.retrieve(subscriptionId);
    const user = await this._getUserFromMetadata(subscription.metadata?.firebase_uid);
    if (!user) return;

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

    // Mirror the entitlement into Firestore (the mobile app reads it there)
    await this._writeFirestoreEntitlement(user.firebaseUid, periodEnd.getTime(), 'stripe');
  }

  private async _handleSubscriptionDeleted(subscription: Stripe.Subscription) {
    const user = await this._getUserFromMetadata(subscription.metadata?.firebase_uid);
    if (!user) return;

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

  // ================================================================
  //  IAP VERIFICATION + SERVER-SIDE ENTITLEMENT GRANTS
  //  Firestore rules block clients from granting themselves premium;
  //  entitlements can only be written here via the Admin SDK.
  // ================================================================

  /**
   * Verifies an in-app purchase and grants the entitlement in Firestore.
   * Idempotent by transactionId.
   */
  async verifyIapPurchase(firebaseUid: string, dto: VerifyIapDto) {
    const planId = dto.productId.replace(/_(us|gb|mx)$/i, '');
    const catalog = RECEIPT_CATALOG[dto.productId] ?? RECEIPT_CATALOG[planId];

    if (planId === 'free_trial') {
      return this._grantFreeTrial(firebaseUid);
    }
    if (!catalog) {
      throw new BadRequestException(`Unknown product: ${dto.productId}`);
    }

    // Idempotency: same transactionId can only grant once
    const existing = await this.paymentRepository.findOne({
      where: { providerPaymentId: dto.transactionId },
    });
    if (existing && (existing.metadata as any)?.grantedAt) {
      return { verified: true, alreadyGranted: true };
    }

    // Verify with the store when configured. When the store credentials are
    // NOT configured we still grant (logged as unverified) so purchases keep
    // working — but every grant is recorded server-side for audit.
    // Set APPLE_SHARED_SECRET / GOOGLE_PLAY_SA_JSON+GOOGLE_PLAY_PACKAGE_NAME
    // in production to enforce real receipt validation.
    let verifiedBy = 'unverified';
    let expiryMs: number | null = null;

    if (dto.platform === 'ios') {
      const r = await this._verifyAppleReceipt(dto.verificationData, planId);
      verifiedBy = r.verified ? 'apple' : 'unverified';
      expiryMs = r.expiryMs;
    } else if (dto.platform === 'android') {
      const r = await this._verifyGooglePurchase(
        dto.verificationData,
        dto.productId,
        planId,
      );
      verifiedBy = r.verified ? 'google' : 'unverified';
      expiryMs = r.expiryMs;
    } else {
      throw new BadRequestException(`Invalid platform: ${dto.platform}`);
    }

    // Atomic grant + idempotency marker: two concurrent verify calls for the
    // same transactionId cannot both pass — the second sees the marker doc.
    const db = admin.firestore();
    const markerRef = db
      .collection('iap_grants')
      .doc(`${firebaseUid}_${dto.transactionId}`);
    const duplicated = await db.runTransaction(async (tx) => {
      const marker = await tx.get(markerRef);
      if (marker.exists) return true;
      await this._grantEntitlement(
        firebaseUid,
        planId,
        expiryMs,
        dto.transactionId,
        dto.platform,
        tx,
      );
      tx.create(markerRef, {
        uid: firebaseUid,
        transactionId: dto.transactionId,
        planId,
        verifiedBy,
        grantedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return false;
    });
    if (duplicated) {
      return { verified: true, alreadyGranted: true };
    }

    // Record the payment (audit trail)
    let user = await this.userRepository.findOne({ where: { firebaseUid } });
    if (!user) {
      user = await this.userRepository.save(
        this.userRepository.create({ firebaseUid }),
      );
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

    this.logger.log(
      `IAP granted uid=${firebaseUid} product=${planId} tx=${dto.transactionId} verifiedBy=${verifiedBy}`,
    );

    return { verified: true, verifiedBy, alreadyGranted: false };
  }

  /** Grants a 7-day free trial once per account, server-validated. */
  private async _grantFreeTrial(firebaseUid: string) {
    const db = admin.firestore();
    const userRef = db.collection('users').doc(firebaseUid);

    const granted = await db.runTransaction(async (tx) => {
      const snap = await tx.get(userRef);
      if (!snap.exists) return false;
      if (snap.get('hasUsedFreeTrial') === true) return false;

      const endMs = Date.now() + 7 * 24 * 3600 * 1000;
      tx.set(
        userRef,
        {
          hasUsedFreeTrial: true,
          isPremium: true,
          planId: 'premium',
          subscription: {
            planId: 'free_trial',
            planName: 'Prueba Gratis',
            endDate: admin.firestore.Timestamp.fromMillis(endMs),
            autoRenew: false,
            status: 'trial',
          },
        },
        { merge: true },
      );
      tx.set(
        db.collection('subscriptions').doc(firebaseUid),
        {
          userId: firebaseUid,
          planId: 'premium',
          startDate: Date.now(),
          endDate: endMs,
          isActive: true,
          autoRenew: false,
          paymentMethod: 'free_trial',
        },
        { merge: true },
      );
      return true;
    });

    if (!granted) {
      throw new BadRequestException('Free trial already used');
    }
    return { verified: true, granted: 'free_trial' };
  }

  /** Writes the entitlement for a verified purchase via the Admin SDK.
   *  When [tx] is provided every write joins that transaction so the grant
   *  and the caller's idempotency marker commit atomically. */
  private async _grantEntitlement(
    firebaseUid: string,
    planId: string,
    expiryMs: number | null,
    transactionId: string,
    platform: string,
    tx?: admin.firestore.Transaction,
  ) {
    const db = admin.firestore();
    const userRef = db.collection('users').doc(firebaseUid);
    const now = Date.now();

    switch (planId) {
      case 'premium_monthly':
      case 'premium_annual': {
        const days = planId === 'premium_annual' ? 365 : 30;
        const endMs = expiryMs ?? now + days * 86400000;
        const subData = {
          userId: firebaseUid,
          planId: 'premium',
          startDate: now,
          endDate: endMs,
          isActive: true,
          autoRenew: true,
          paymentMethod: platform === 'stripe' ? 'stripe' : 'iap',
          storeTransactionId: transactionId,
          store: platform,
        };
        const subRef = db.collection('subscriptions').doc(firebaseUid);
        const userEntitlement = {
          isPremium: true,
          planId: 'premium',
          subscription: {
            status: 'active',
            autoRenew: true,
            source: platform === 'stripe' ? 'stripe' : 'iap',
            endDate: admin.firestore.Timestamp.fromMillis(endMs),
          },
        };
        if (tx) {
          tx.set(subRef, subData, { merge: true });
          tx.set(userRef, userEntitlement, { merge: true });
        } else {
          await subRef.set(subData, { merge: true });
          await this._writeFirestoreEntitlement(firebaseUid, endMs, platform);
        }
        break;
      }
      case 'boost': {
        const endMs = now + 30 * 60000;
        const boostRef = userRef.collection('boosts').doc();
        const boostData = {
          durationMinutes: 30,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          transactionId,
        };
        const boostFlag = {
          isBoosted: true,
          boostEndTime: admin.firestore.Timestamp.fromMillis(endMs),
        };
        if (tx) {
          tx.create(boostRef, boostData);
          tx.set(userRef, boostFlag, { merge: true });
        } else {
          await boostRef.set(boostData);
          await userRef.set(boostFlag, { merge: true });
        }
        break;
      }
      case 'super_like': {
        const data = {
          superLikesAvailable: admin.firestore.FieldValue.increment(1),
        };
        if (tx) {
          tx.set(userRef, data, { merge: true });
        } else {
          await userRef.set(data, { merge: true });
        }
        break;
      }
      case 'premium_verification': {
        const data = {
          isVerified: true,
          'verification.isPremiumVerified': true,
          'verification.premiumVerifiedAt':
            admin.firestore.FieldValue.serverTimestamp(),
        };
        if (tx) {
          tx.set(userRef, data, { merge: true });
        } else {
          await userRef.set(data, { merge: true });
        }
        break;
      }
      case 'highlight_listing': {
        const until = now + 24 * 3600 * 1000;
        const data = {
          isListingHighlighted: true,
          listingHighlightedUntil:
            admin.firestore.Timestamp.fromMillis(until),
        };
        if (tx) {
          tx.set(userRef, data, { merge: true });
        } else {
          await userRef.set(data, { merge: true });
        }
        break;
      }
      default:
        throw new BadRequestException(`Cannot grant product: ${planId}`);
    }
  }

  /** Mirrors premium status into Firestore (single source for the app). */
  private async _writeFirestoreEntitlement(
    firebaseUid: string,
    endMs: number,
    source: string,
  ) {
    try {
      await admin.firestore().collection('users').doc(firebaseUid).set(
        {
          isPremium: true,
          planId: 'premium',
          subscription: {
            status: 'active',
            autoRenew: true,
            source,
            endDate: admin.firestore.Timestamp.fromMillis(endMs),
          },
        },
        { merge: true },
      );
    } catch (e) {
      this.logger.warn(`Firestore entitlement write failed for ${firebaseUid}: ${e}`);
    }
  }

  /** Removes premium status from Firestore. */
  private async _revokeFirestoreEntitlement(firebaseUid: string) {
    try {
      const db = admin.firestore();
      await db.collection('users').doc(firebaseUid).set(
        {
          isPremium: false,
          planId: 'basic',
          subscription: {
            status: 'expired',
          },
        },
        { merge: true },
      );
      await db.collection('subscriptions').doc(firebaseUid).set(
        { isActive: false, autoRenew: false },
        { merge: true },
      );
    } catch (e) {
      this.logger.warn(`Firestore entitlement revoke failed for ${firebaseUid}: ${e}`);
    }
  }

  /**
   * Verifies an App Store receipt via verifyReceipt.
   * Returns { verified, expiryMs }. When APPLE_SHARED_SECRET is not
   * configured the check is skipped (grant proceeds, marked unverified).
   */
  private async _verifyAppleReceipt(
    receiptData: string | undefined,
    planId: string,
  ): Promise<{ verified: boolean; expiryMs: number | null }> {
    const secret = this.configService.get<string>('APPLE_SHARED_SECRET');
    if (!secret) {
      this.logger.warn('APPLE_SHARED_SECRET not set — skipping Apple receipt validation');
      return { verified: false, expiryMs: null };
    }
    if (!receiptData) {
      throw new BadRequestException('Missing receipt data');
    }

    const verify = async (url: string) => {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 'receipt-data': receiptData, password: secret }),
      });
      return res.json() as Promise<any>;
    };

    let body = await verify('https://buy.itunes.apple.com/verifyReceipt');
    if (body.status === 21007) {
      body = await verify('https://sandbox.itunes.apple.com/verifyReceipt');
    }
    if (body.status !== 0) {
      throw new BadRequestException(`Apple receipt invalid (status=${body.status})`);
    }

    const isSubscription = planId === 'premium_monthly' || planId === 'premium_annual';
    const items: any[] = body.latest_receipt_info ?? body.receipt?.in_app ?? [];
    const match = items
      .filter((i) => i.product_id === planId || i.product_id?.startsWith(planId))
      .sort((a, b) => Number(b.expires_date_ms ?? 0) - Number(a.expires_date_ms ?? 0))[0];

    if (!match) {
      throw new BadRequestException('Product not found in receipt');
    }
    if (isSubscription) {
      const expiryMs = Number(match.expires_date_ms ?? 0);
      if (expiryMs <= Date.now()) {
        throw new BadRequestException('Subscription expired');
      }
      return { verified: true, expiryMs };
    }
    return { verified: true, expiryMs: null };
  }

  /**
   * Verifies a Google Play purchase token via androidpublisher REST API
   * (service account JWT → access token, no extra deps).
   */
  private async _verifyGooglePurchase(
    purchaseToken: string | undefined,
    productId: string,
    planId: string,
  ): Promise<{ verified: boolean; expiryMs: number | null }> {
    const saJson = this.configService.get<string>('GOOGLE_PLAY_SA_JSON');
    const packageName = this.configService.get<string>('GOOGLE_PLAY_PACKAGE_NAME');
    if (!saJson || !packageName) {
      this.logger.warn('GOOGLE_PLAY_SA_JSON/GOOGLE_PLAY_PACKAGE_NAME not set — skipping Google verification');
      return { verified: false, expiryMs: null };
    }
    if (!purchaseToken) {
      throw new BadRequestException('Missing purchase token');
    }

    const sa = JSON.parse(saJson) as { client_email: string; private_key: string };
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
      throw new BadRequestException(`Google purchase invalid (HTTP ${res.status})`);
    }
    const body = (await res.json()) as any;

    if (isSubscription) {
      const expiryMs = Number(body.expiryTimeMillis ?? 0);
      if (expiryMs <= Date.now()) {
        throw new BadRequestException('Subscription expired');
      }
      return { verified: true, expiryMs };
    }
    // Consumables: purchaseState 0 = purchased
    if (body.purchaseState !== 0) {
      throw new BadRequestException('Purchase not completed');
    }
    return { verified: true, expiryMs: null };
  }

  /** Service-account JWT → OAuth2 access token (androidpublisher scope). */
  private async _googleAccessToken(sa: {
    client_email: string;
    private_key: string;
  }): Promise<string> {
    const now = Math.floor(Date.now() / 1000);
    const b64 = (o: object) =>
      Buffer.from(JSON.stringify(o)).toString('base64url');
    const unsigned =
      `${b64({ alg: 'RS256', typ: 'JWT' })}.` +
      `${b64({
        iss: sa.client_email,
        scope: 'https://www.googleapis.com/auth/androidpublisher',
        aud: 'https://oauth2.googleapis.com/token',
        iat: now,
        exp: now + 3600,
      })}`;
    const sign = createSign('RSA-SHA256');
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
    const body = (await res.json()) as any;
    if (!body.access_token) {
      throw new ServiceUnavailableException('Google auth failed');
    }
    return body.access_token as string;
  }
}
