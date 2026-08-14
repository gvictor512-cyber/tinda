import { Controller, Post, Req, Res, Headers, HttpStatus } from '@nestjs/common';
import { Response } from 'express';
import { PaymentsService } from './payments.service';

@Controller('payments/webhook')
export class PaymentsWebhookController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post()
  async handleWebhook(
    @Req() req: any,
    @Res() res: Response,
    @Headers('stripe-signature') signature: string,
  ) {
    try {
      const rawBody = (req as any).rawBody ?? req.body;
      await this.paymentsService.handleWebhook(rawBody, signature);
      return res.status(HttpStatus.OK).json({ received: true });
    } catch (e) {
      return res.status(HttpStatus.BAD_REQUEST).send(`Webhook Error: ${e.message}`);
    }
  }
}
