import { Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { Payment } from './entities/payment.entity';
import { UserCancellation } from './entities/user-cancellation.entity';
export declare class AdminService {
    private readonly userRepository;
    private readonly paymentRepository;
    private readonly cancellationRepository;
    constructor(userRepository: Repository<User>, paymentRepository: Repository<Payment>, cancellationRepository: Repository<UserCancellation>);
    private getDateRange;
    getDashboard(period?: string): Promise<{
        period: string;
        totalUsers: number;
        newUsers: number;
        activeSubscriptions: number;
        totalPayments: number;
        totalRevenue: number;
        cancellations: number;
    }>;
    getUsers(take?: number, skip?: number): Promise<User[]>;
    getNewUsers(period?: string, take?: number, skip?: number): Promise<User[]>;
    getPayments(take?: number, skip?: number): Promise<Payment[]>;
    getCancellations(take?: number, skip?: number): Promise<UserCancellation[]>;
}
