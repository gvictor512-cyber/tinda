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
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentsService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const stripe_1 = __importDefault(require("stripe"));
const user_entity_1 = require("../users/entities/user.entity");
const payment_entity_1 = require("../admin/entities/payment.entity");
const subscription_entity_1 = require("../premium/entities/subscription.entity");
let PaymentsService = class PaymentsService {
    constructor(configService, userRepository, paymentRepository, subscriptionRepository) {
        this.configService = configService;
        this.userRepository = userRepository;
        this.paymentRepository = paymentRepository;
        this.subscriptionRepository = subscriptionRepository;
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
    }
};
exports.PaymentsService = PaymentsService;
exports.PaymentsService = PaymentsService = __decorate([
    (0, common_1.Injectable)(),
    __param(1, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(2, (0, typeorm_1.InjectRepository)(payment_entity_1.Payment)),
    __param(3, (0, typeorm_1.InjectRepository)(subscription_entity_1.Subscription)),
    __metadata("design:paramtypes", [config_1.ConfigService,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], PaymentsService);
//# sourceMappingURL=payments.service.js.map