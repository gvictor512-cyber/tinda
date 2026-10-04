import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import Stripe from 'stripe';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { SetupSubscriptionDto } from './dto/setup-subscription.dto';
import { SendReceiptDto } from './dto/send-receipt.dto';
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
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);
  private readonly stripe: Stripe;
  private readonly destinationBankAccount: string | undefined;

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
    const params: Stripe.PaymentIntentCreateParams = {
      amount: dto.amount,
      currency: dto.currency.toLowerCase(),
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

  async cancelSubscription(subscriptionId: string) {
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
  }
}
