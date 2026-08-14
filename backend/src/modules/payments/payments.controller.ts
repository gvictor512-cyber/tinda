import { Controller, Post, Body, Request, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { SetupSubscriptionDto } from './dto/setup-subscription.dto';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';

@ApiTags('payments')
@Controller('payments')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('customer')
  @HttpCode(HttpStatus.OK)
  async createCustomer(@Body() dto: CreateCustomerDto) {
    return this.paymentsService.createCustomer(dto);
  }

  @Post('payment-intent')
  @HttpCode(HttpStatus.OK)
  async createPaymentIntent(
    @Request() req,
    @Body() dto: CreatePaymentIntentDto,
  ) {
    return this.paymentsService.createPaymentIntent(req.user.uid, dto);
  }

  @Post('subscription')
  @HttpCode(HttpStatus.OK)
  async setupSubscription(
    @Request() req,
    @Body() dto: SetupSubscriptionDto,
  ) {
    return this.paymentsService.setupSubscription(req.user.uid, dto);
  }

  @Post('subscription/cancel')
  @HttpCode(HttpStatus.OK)
  async cancelSubscription(
    @Request() req,
    @Body('subscriptionId') subscriptionId: string,
  ) {
    return this.paymentsService.cancelSubscription(subscriptionId);
  }
}
