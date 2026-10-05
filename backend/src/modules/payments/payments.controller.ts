import { Controller, Post, Body, Request, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { CreatePaymentIntentDto } from './dto/create-payment-intent.dto';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { SetupSubscriptionDto } from './dto/setup-subscription.dto';
import { SendReceiptDto } from './dto/send-receipt.dto';
import { VerifyIapDto } from './dto/verify-iap.dto';
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
    return this.paymentsService.cancelSubscription(req.user.uid, subscriptionId);
  }

  /**
   * Notifica una compra IAP completada: registra el pago y envia la factura
   * por email. Idempotente por transactionId.
   */
  @Post('receipt')
  @HttpCode(HttpStatus.OK)
  async sendPurchaseReceipt(@Request() req, @Body() dto: SendReceiptDto) {
    return this.paymentsService.sendPurchaseReceipt(req.user.uid, req.user.email, dto);
  }

  /**
   * Verifica una compra IAP contra Apple/Google y concede la ventaja
   * (premium, boost, super like...) escribiendola en Firestore con el
   * Admin SDK. El cliente ya NO puede concedersela a si mismo porque
   * las reglas de Firestore bloquean esas escrituras.
   */
  @Post('iap/verify')
  @HttpCode(HttpStatus.OK)
  async verifyIap(@Request() req, @Body() dto: VerifyIapDto) {
    return this.paymentsService.verifyIapPurchase(req.user.uid, dto);
  }
}
