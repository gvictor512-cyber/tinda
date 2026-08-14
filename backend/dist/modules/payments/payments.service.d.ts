import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { SetupSubscriptionDto } from './dto/setup-subscription.dto';
export declare class PaymentsService {
    private readonly configService;
    private readonly stripe;
    private readonly destinationBankAccount;
    constructor(configService: ConfigService);
    createCustomer(dto: CreateCustomerDto): Promise<Stripe.Response<Stripe.Customer>>;
    createPaymentIntent(firebaseUid: string, dto: CreatePaymentIntentDto): Promise<Stripe.Response<Stripe.PaymentIntent>>;
    setupSubscription(firebaseUid: string, dto: SetupSubscriptionDto): Promise<Stripe.Response<Stripe.Subscription>>;
    cancelSubscription(subscriptionId: string): Promise<Stripe.Response<Stripe.Subscription>>;
    getCustomerTransactions(customerId: string, limit?: number): Promise<Stripe.Response<Stripe.ApiList<Stripe.Charge>>>;
    handleWebhook(payload: Buffer, signature: string | undefined): Promise<{
        received: boolean;
    }>;
}
