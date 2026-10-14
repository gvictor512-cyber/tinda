import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';

const firestoreGet = jest.fn();
jest.mock('firebase-admin', () => ({
  firestore: () => ({
    collection: () => ({
      doc: () => ({ get: firestoreGet }),
    }),
  }),
}));

import { PremiumService } from './premium.service';

const makeUser = (overrides: Partial<any> = {}) => ({
  id: 'u1',
  firebaseUid: 'fb1',
  isPremium: false,
  premiumExpiresAt: null,
  ...overrides,
});

const mockFirestoreSubscription = (data: any) => {
  firestoreGet.mockResolvedValue({ exists: !!data, data: () => data });
};

describe('PremiumService', () => {
  let service: PremiumService;
  let subscriptionsRepository: any;
  let usersRepository: any;
  let dailyLimitsRepository: any;
  const originalEnv = process.env.NODE_ENV;

  beforeEach(() => {
    jest.clearAllMocks();
    subscriptionsRepository = {
      findOne: jest.fn(),
      create: jest.fn((v) => v),
      save: jest.fn(async (v) => v),
    };
    usersRepository = {
      findOne: jest.fn(),
      save: jest.fn(async (v) => v),
    };
    dailyLimitsRepository = {
      findOne: jest.fn(),
      create: jest.fn((v) => v),
      save: jest.fn(async (v) => v),
    };
    service = new PremiumService(
      subscriptionsRepository,
      usersRepository,
      dailyLimitsRepository,
    );
  });

  afterEach(() => {
    process.env.NODE_ENV = originalEnv;
  });

  describe('getPremiumStatus', () => {
    it('throws NotFoundException when the user does not exist', async () => {
      usersRepository.findOne.mockResolvedValue(null);
      await expect(service.getPremiumStatus('fb1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('returns status without subscription details for a free user', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser());
      subscriptionsRepository.findOne.mockResolvedValue(null);

      const result = await service.getPremiumStatus('fb1');

      expect(result.isPremium).toBe(false);
      expect(result.subscription).toBeNull();
    });
  });

  describe('createSubscription', () => {
    it('rejects if the user already has an active subscription', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser());
      subscriptionsRepository.findOne.mockResolvedValue({ id: 's1' });

      await expect(
        service.createSubscription('fb1', {
          planType: 'premium_monthly',
        } as any),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('rejects without a verified entitlement in production', async () => {
      process.env.NODE_ENV = 'production';
      usersRepository.findOne.mockResolvedValue(makeUser());
      subscriptionsRepository.findOne.mockResolvedValue(null);
      mockFirestoreSubscription(null);

      await expect(
        service.createSubscription('fb1', {
          planType: 'premium_monthly',
        } as any),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('grants premium when a verified Firestore entitlement exists', async () => {
      process.env.NODE_ENV = 'production';
      const user = makeUser();
      usersRepository.findOne.mockResolvedValue(user);
      subscriptionsRepository.findOne.mockResolvedValue(null);
      mockFirestoreSubscription({
        isActive: true,
        endDate: Date.now() + 30 * 86400000,
      });

      const result = await service.createSubscription('fb1', {
        planType: 'premium_monthly',
      } as any);

      expect(result.success).toBe(true);
      expect(user.isPremium).toBe(true);
      expect(usersRepository.save).toHaveBeenCalledWith(user);
    });
  });

  describe('cancelSubscription', () => {
    it('throws BadRequestException when there is no active subscription', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser());
      subscriptionsRepository.findOne.mockResolvedValue(null);

      await expect(service.cancelSubscription('fb1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('deactivates the subscription but keeps premium until end date', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser({ isPremium: true }));
      const sub = { isActive: true, autoRenew: true };
      subscriptionsRepository.findOne.mockResolvedValue(sub);

      const result = await service.cancelSubscription('fb1');

      expect(result.success).toBe(true);
      expect(sub.isActive).toBe(false);
      expect(sub.autoRenew).toBe(false);
    });
  });

  describe('useLike', () => {
    it('increments usage for free users', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser());
      const limits = { likesUsed: 9, superLikesUsed: 0, boostsUsed: 0 };
      dailyLimitsRepository.findOne.mockResolvedValue(limits);

      const result = await service.useLike('fb1');

      expect(result).toEqual({ success: true, remaining: 0 });
      expect(limits.likesUsed).toBe(10);
    });

    it('throws BadRequestException at the daily limit', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser());
      dailyLimitsRepository.findOne.mockResolvedValue({
        likesUsed: 10,
        superLikesUsed: 0,
        boostsUsed: 0,
      });

      await expect(service.useLike('fb1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });
  });

  describe('boostProfile', () => {
    it('is rejected for free users', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser());
      await expect(service.boostProfile('fb1')).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });

    it('increments the boost counter for premium users', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser({ isPremium: true }));
      const limits = { likesUsed: 0, superLikesUsed: 0, boostsUsed: 0 };
      dailyLimitsRepository.findOne.mockResolvedValue(limits);

      const result = await service.boostProfile('fb1');

      expect(result.success).toBe(true);
      expect(limits.boostsUsed).toBe(1);
    });
  });
});
