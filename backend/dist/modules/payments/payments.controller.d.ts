import { PaymentsService } from './payments.service';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { SetupSubscriptionDto } from './dto/setup-subscription.dto';
import { SendReceiptDto } from './dto/send-receipt.dto';
import { VerifyIapDto } from './dto/verify-iap.dto';
export declare class PaymentsController {
    private readonly paymentsService;
    constructor(paymentsService: PaymentsService);
    createCustomer(dto: CreateCustomerDto): Promise<import("stripe").Stripe.Response<import("stripe").Stripe.Customer>>;
    createPaymentIntent(req: any, dto: CreatePaymentIntentDto): Promise<import("stripe").Stripe.Response<import("stripe").Stripe.PaymentIntent>>;
    setupSubscription(req: any, dto: SetupSubscriptionDto): Promise<import("stripe").Stripe.Response<import("stripe").Stripe.Subscription>>;
    cancelSubscription(req: any, subscriptionId: string): Promise<import("stripe").Stripe.Response<import("stripe").Stripe.Subscription>>;
    sendPurchaseReceipt(req: any, dto: SendReceiptDto): Promise<{
        sent: boolean;
        alreadyRecorded: boolean;
        invoiceNumber: string;
    }>;
    verifyIap(req: any, dto: VerifyIapDto): Promise<{
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
}
