import { AdminService } from './admin.service';
export declare class AdminController {
    private readonly adminService;
    constructor(adminService: AdminService);
    getDashboard(period?: string): Promise<{
        period: string;
        totalUsers: number;
        newUsers: number;
        activeSubscriptions: number;
        totalPayments: number;
        totalRevenue: number;
        cancellations: number;
    }>;
    getUsers(take?: number, skip?: number): Promise<import("../users/entities/user.entity").User[]>;
    getNewUsers(period?: string, take?: number, skip?: number): Promise<import("../users/entities/user.entity").User[]>;
    getPayments(take?: number, skip?: number): Promise<import("./entities/payment.entity").Payment[]>;
    getCancellations(take?: number, skip?: number): Promise<import("./entities/user-cancellation.entity").UserCancellation[]>;
}
