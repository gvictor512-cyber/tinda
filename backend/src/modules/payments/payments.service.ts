import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import Stripe from 'stripe';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { SetupSubscriptionDto } from './dto/setup-subscription.dto';
import { User } from '../users/entities/user.entity';
import { Payment } from '../admin/entities/payment.entity';
import { Subscription } from '../premium/entities/subscription.entity';

@Injectable()
export class PaymentsService {
  private readonly stripe: Stripe;
  private readonly destinationBankAccount: string | undefined;

  constructor(
    private readonly configService: ConfigService,
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
