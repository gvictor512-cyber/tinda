import { Response } from 'express';
import { PaymentsService } from './payments.service';
export declare class PaymentsWebhookController {
    private readonly paymentsService;
    constructor(paymentsService: PaymentsService);
    handleWebhook(req: any, res: Response, signature: string): Promise<Response<any, Record<string, any>>>;
}
