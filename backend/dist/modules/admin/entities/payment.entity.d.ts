import { User } from '../../users/entities/user.entity';
export declare class Payment {
    id: string;
    userId: string;
    user: User;
    amount: number;
    currency: string;
    status: 'pending' | 'succeeded' | 'failed' | 'refunded';
    provider: string;
    providerPaymentId: string;
    planType: string;
    metadata: Record<string, any>;
    createdAt: Date;
    updatedAt: Date;
}
