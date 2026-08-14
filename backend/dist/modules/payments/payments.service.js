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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentsService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const stripe_1 = __importDefault(require("stripe"));
let PaymentsService = class PaymentsService {
    constructor(configService) {
        this.configService = configService;
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
        const params = {
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
            case 'payment_intent.succeeded': {
                const paymentIntent = event.data.object;
                break;
            }
            case 'payment_intent.payment_failed': {
                const failedPayment = event.data.object;
                break;
            }
            case 'invoice.payment_succeeded': {
                const invoice = event.data.object;
                break;
            }
            case 'customer.subscription.deleted': {
                const subscription = event.data.object;
                break;
            }
        }
        return { received: true };
    }
};
exports.PaymentsService = PaymentsService;
exports.PaymentsService = PaymentsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], PaymentsService);
//# sourceMappingURL=payments.service.js.map