import { OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Repository } from 'typeorm';
import Stripe from 'stripe';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { SetupSubscriptionDto } from './dto/setup-subscription.dto';
import { SendReceiptDto } from './dto/send-receipt.dto';
import { VerifyIapDto } from './dto/verify-iap.dto';
import { MailService } from '../mail/mail.service';
import { User } from '../users/entities/user.entity';
import { Payment } from '../admin/entities/payment.entity';
import { Subscription } from '../premium/entities/subscription.entity';
export declare class PaymentsService implements OnModuleInit, OnModuleDestroy {
    private readonly configService;
    private readonly mailService;
    private readonly userRepository;
    private readonly paymentRepository;
    private readonly subscriptionRepository;
    private readonly logger;
    private readonly stripe;
    private readonly destinationBankAccount;
    private _expiryTimer;
    onModuleInit(): void;
    onModuleDestroy(): void;
    private _sweepExpiredSubscriptions;
    constructor(configService: ConfigService, mailService: MailService, userRepository: Repository<User>, paymentRepository: Repository<Payment>, subscriptionRepository: Repository<Subscription>);
    createCustomer(dto: CreateCustomerDto): Promise<Stripe.Response<Stripe.Customer>>;
    createPaymentIntent(firebaseUid: string, dto: CreatePaymentIntentDto): Promise<Stripe.Response<Stripe.PaymentIntent>>;
    setupSubscription(firebaseUid: string, dto: SetupSubscriptionDto): Promise<Stripe.Response<Stripe.Subscription>>;
    cancelSubscription(subscriptionId: string): Promise<Stripe.Response<Stripe.Subscription>>;
    getCustomerTransactions(customerId: string, limit?: number): Promise<Stripe.Response<Stripe.ApiList<Stripe.Charge>>>;
    sendPurchaseReceipt(firebaseUid: string, tokenEmail: string | undefined, dto: SendReceiptDto): Promise<{
        sent: boolean;
        alreadyRecorded: boolean;
        invoiceNumber: string;
    }>;
    private buildInvoiceNumber;
    handleWebhook(payload: Buffer, signature: string | undefined): Promise<{
        received: boolean;
    }>;
    private _getUserFromMetadata;
    private _handlePaymentIntentSucceeded;
    private _handlePaymentIntentFailed;
    private _handleInvoicePaymentSucceeded;
    private _handleSubscriptionDeleted;
    verifyIapPurchase(firebaseUid: string, dto: VerifyIapDto): Promise<{
        verified: boolean;
        granted: string;
    } | {
        verified: boolean;
        alreadyGranted: boolean;
        verifiedBy?: undefined;
    } | {
        verified: boolean;
        verifiedBy: string;
        alreadyGranted: boolean;
    }>;
    private _grantFreeTrial;
    private _grantEntitlement;
    private _writeFirestoreEntitlement;
    private _revokeFirestoreEntitlement;
    private _verifyAppleReceipt;
    private _verifyGooglePurchase;
    private _googleAccessToken;
}
