import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { Payment } from './entities/payment.entity';
import { UserCancellation } from './entities/user-cancellation.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
    @InjectRepository(UserCancellation)
    private readonly cancellationRepository: Repository<UserCancellation>,
  ) {}

  private getDateRange(period: string): { start: Date; end: Date } {
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
        where: { createdAt: Between(start, end) },
      }),
      this.userRepository.count({ where: { isPremium: true } }),
      this.paymentRepository.find({
        where: { createdAt: Between(start, end) },
      }),
    ]);

    const totalRevenue = payments.reduce((sum, payment) => {
      return payment.status === 'succeeded' ? sum + (payment.amount || 0) : sum;
    }, 0);

    const cancellations = await this.cancellationRepository.count({
      where: { createdAt: Between(start, end) },
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
      where: { createdAt: Between(start, end) },
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
}
