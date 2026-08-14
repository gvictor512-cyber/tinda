import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { SetupSubscriptionDto } from './dto/setup-subscription.dto';

@Injectable()
export class PaymentsService {
  private readonly stripe: Stripe;
  private readonly destinationBankAccount: string | undefined;

  constructor(private readonly configService: ConfigService) {
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
      case 'payment_intent.succeeded': {
        const paymentIntent = event.data.object as any;
        // Guardar en Firestore si usas Firebase admin en este servicio
        break;
      }
      case 'payment_intent.payment_failed': {
        const failedPayment = event.data.object as any;
        break;
      }
      case 'invoice.payment_succeeded': {
        const invoice = event.data.object as any;
        break;
      }
      case 'customer.subscription.deleted': {
        const subscription = event.data.object as any;
        break;
      }
    }

    return { received: true };
  }
}
