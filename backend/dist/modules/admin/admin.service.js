"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const user_entity_1 = require("../users/entities/user.entity");
const payment_entity_1 = require("./entities/payment.entity");
const user_cancellation_entity_1 = require("./entities/user-cancellation.entity");
let AdminService = class AdminService {
    constructor(userRepository, paymentRepository, cancellationRepository) {
        this.userRepository = userRepository;
        this.paymentRepository = paymentRepository;
        this.cancellationRepository = cancellationRepository;
    }
    getDateRange(period) {
        const end = new Date();
        const start = new Date();
        switch (period) {
            case 'today':
                start.setHours(0, 0, 0, 0);
                break;
            case 'week':
                start.setDate(end.getDate() - 7);
                break;
            case 'month':
                start.setMonth(end.getMonth() - 1);
                break;
            case 'year':
                start.setFullYear(end.getFullYear() - 1);
                break;
            case 'all':
            default:
                return { start: new Date(0), end };
        }
        return { start, end };
    }
    async getDashboard(period = 'all') {
        const { start, end } = this.getDateRange(period);
        const [totalUsers, newUsers, activeSubscriptions, payments] = await Promise.all([
            this.userRepository.count(),
            this.userRepository.count({
                where: { createdAt: (0, typeorm_2.Between)(start, end) },
            }),
            this.userRepository.count({ where: { isPremium: true } }),
            this.paymentRepository.find({
                where: { createdAt: (0, typeorm_2.Between)(start, end) },
            }),
        ]);
        const totalRevenue = payments.reduce((sum, payment) => {
            return payment.status === 'succeeded' ? sum + (payment.amount || 0) : sum;
        }, 0);
        const cancellations = await this.cancellationRepository.count({
            where: { createdAt: (0, typeorm_2.Between)(start, end) },
        });
        return {
            period,
            totalUsers,
            newUsers,
            activeSubscriptions,
            totalPayments: payments.length,
            totalRevenue,
            cancellations,
        };
    }
    async getUsers(take = 20, skip = 0) {
        return this.userRepository.find({
            order: { createdAt: 'DESC' },
            take,
            skip,
        });
    }
    async getNewUsers(period = 'week', take = 20, skip = 0) {
        const { start, end } = this.getDateRange(period);
        return this.userRepository.find({
            where: { createdAt: (0, typeorm_2.Between)(start, end) },
            order: { createdAt: 'DESC' },
            take,
            skip,
        });
    }
    async getPayments(take = 20, skip = 0) {
        return this.paymentRepository.find({
            relations: ['user'],
            order: { createdAt: 'DESC' },
            take,
            skip,
        });
    }
    async getCancellations(take = 20, skip = 0) {
        return this.cancellationRepository.find({
            relations: ['user'],
            order: { createdAt: 'DESC' },
            take,
            skip,
        });
    }
};
exports.AdminService = AdminService;
exports.AdminService = AdminService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(1, (0, typeorm_1.InjectRepository)(payment_entity_1.Payment)),
    __param(2, (0, typeorm_1.InjectRepository)(user_cancellation_entity_1.UserCancellation)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], AdminService);
//# sourceMappingURL=admin.service.js.map