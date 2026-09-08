import { ConfigService } from '@nestjs/config';
import { Repository } from 'typeorm';
import Stripe from 'stripe';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { SetupSubscriptionDto } from './dto/setup-subscription.dto';
import { User } from '../users/entities/user.entity';
import { Payment } from '../admin/entities/payment.entity';
import { Subscription } from '../premium/entities/subscription.entity';
export declare class PaymentsService {
    private readonly configService;
    private readonly userRepository;
    private readonly paymentRepository;
    private readonly subscriptionRepository;
    private readonly stripe;
    private readonly destinationBankAccount;
    constructor(configService: ConfigService, userRepository: Repository<User>, paymentRepository: Repository<Payment>, subscriptionRepository: Repository<Subscription>);
    createCustomer(dto: CreateCustomerDto): Promise<Stripe.Response<Stripe.Customer>>;
    createPaymentIntent(firebaseUid: string, dto: CreatePaymentIntentDto): Promise<Stripe.Response<Stripe.PaymentIntent>>;
    setupSubscription(firebaseUid: string, dto: SetupSubscriptionDto): Promise<Stripe.Response<Stripe.Subscription>>;
    cancelSubscription(subscriptionId: string): Promise<Stripe.Response<Stripe.Subscription>>;
    getCustomerTransactions(customerId: string, limit?: number): Promise<Stripe.Response<Stripe.ApiList<Stripe.Charge>>>;
    handleWebhook(payload: Buffer, signature: string | undefined): Promise<{
        received: boolean;
    }>;
    private _getUserFromMetadata;
    private _handlePaymentIntentSucceeded;
    private _handlePaymentIntentFailed;
    private _handleInvoicePaymentSucceeded;
    private _handleSubscriptionDeleted;
}
