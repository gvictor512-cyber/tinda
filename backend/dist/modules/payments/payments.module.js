"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentsModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const typeorm_1 = require("@nestjs/typeorm");
const payments_controller_1 = require("./payments.controller");
const payments_webhook_controller_1 = require("./payments-webhook.controller");
const payments_service_1 = require("./payments.service");
const user_entity_1 = require("../users/entities/user.entity");
const payment_entity_1 = require("../admin/entities/payment.entity");
const subscription_entity_1 = require("../premium/entities/subscription.entity");
const mail_module_1 = require("../mail/mail.module");
let PaymentsModule = class PaymentsModule {
};
exports.PaymentsModule = PaymentsModule;
exports.PaymentsModule = PaymentsModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule,
            mail_module_1.MailModule,
            typeorm_1.TypeOrmModule.forFeature([user_entity_1.User, payment_entity_1.Payment, subscription_entity_1.Subscription]),
        ],
        controllers: [payments_controller_1.PaymentsController, payments_webhook_controller_1.PaymentsWebhookController],
        providers: [payments_service_1.PaymentsService],
        exports: [payments_service_1.PaymentsService],
    })
], PaymentsModule);
//# sourceMappingURL=payments.module.js.map