import { User } from '../../users/entities/user.entity';
export declare class UserCancellation {
    id: string;
    userId: string;
    user: User;
    cancellationType: 'account_deletion' | 'subscription_cancel' | 'manual_deactivation';
    reason: string;
    metadata: Record<string, any>;
    createdAt: Date;
    updatedAt: Date;
}
