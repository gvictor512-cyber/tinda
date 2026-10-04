import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PaymentsController } from './payments.controller';
import { PaymentsWebhookController } from './payments-webhook.controller';
import { PaymentsService } from './payments.service';
import { User } from '../users/entities/user.entity';
import { Payment } from '../admin/entities/payment.entity';
import { Subscription } from '../premium/entities/subscription.entity';
import { MailModule } from '../mail/mail.module';

@Module({
  imports: [
    ConfigModule,
    MailModule,
    TypeOrmModule.forFeature([User, Payment, Subscription]),
  ],
  controllers: [PaymentsController, PaymentsWebhookController],
  providers: [PaymentsService],
  exports: [PaymentsService],
})
export class PaymentsModule {}
