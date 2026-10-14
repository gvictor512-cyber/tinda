import { NotFoundException } from '@nestjs/common';
import { DailyLimitsService } from './daily-limits.service';

const TODAY = new Date();
TODAY.setHours(0, 0, 0, 0);

const makeUser = (overrides: Partial<any> = {}) => ({
  id: 'u1',
  isPremium: false,
  premiumExpiresAt: null,
  ...overrides,
});

describe('DailyLimitsService', () => {
  let service: DailyLimitsService;
  let dailyLimitsRepository: any;
  let usersRepository: any;

  beforeEach(() => {
    dailyLimitsRepository = {
      findOne: jest.fn(),
      create: jest.fn((v) => v),
      save: jest.fn(async (v) => v),
      remove: jest.fn(),
      createQueryBuilder: jest.fn(),
    };
    usersRepository = {
      findOne: jest.fn(),
      save: jest.fn(),
    };
    service = new DailyLimitsService(dailyLimitsRepository, usersRepository);
  });

  describe('getDailyLimits', () => {
    it('throws NotFoundException when the user does not exist', async () => {
      usersRepository.findOne.mockResolvedValue(null);
      await expect(service.getDailyLimits('u1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('returns full remaining quota for a fresh free user', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser());
      dailyLimitsRepository.findOne.mockResolvedValue(null);

      const result = await service.getDailyLimits('u1');

      expect(result.isPremium).toBe(false);
      expect(result.likesRemaining).toBe(10);
      expect(result.superLikesRemaining).toBe(1);
      expect(dailyLimitsRepository.save).toHaveBeenCalled();
    });

    it('returns unlimited (-1) quota for an active premium user', async () => {
      usersRepository.findOne.mockResolvedValue(
        makeUser({
          isPremium: true,
          premiumExpiresAt: new Date(Date.now() + 86400000),
        }),
      );
      dailyLimitsRepository.findOne.mockResolvedValue({
        likesUsed: 5,
        superLikesUsed: 1,
        boostsUsed: 0,
      });

      const result = await service.getDailyLimits('u1');

      expect(result.isPremium).toBe(true);
      expect(result.likesRemaining).toBe(-1);
      expect(result.superLikesRemaining).toBe(-1);
    });

    it('treats an expired premium user as free', async () => {
      usersRepository.findOne.mockResolvedValue(
        makeUser({
          isPremium: true,
          premiumExpiresAt: new Date(Date.now() - 86400000),
        }),
      );
      dailyLimitsRepository.findOne.mockResolvedValue({
        likesUsed: 3,
        superLikesUsed: 0,
        boostsUsed: 0,
      });

      const result = await service.getDailyLimits('u1');

      expect(result.isPremium).toBe(false);
      expect(result.likesRemaining).toBe(7);
    });
  });

  describe('incrementLikes', () => {
    it('increments and reports the remaining count', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser());
      const limits = { likesUsed: 4, superLikesUsed: 0, boostsUsed: 0 };
      dailyLimitsRepository.findOne.mockResolvedValue(limits);

      const result = await service.incrementLikes('u1');

      expect(result).toEqual({ success: true, remaining: 5 });
      expect(limits.likesUsed).toBe(5);
      expect(dailyLimitsRepository.save).toHaveBeenCalledWith(limits);
    });

    it('rejects when the free daily limit is reached', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser());
      dailyLimitsRepository.findOne.mockResolvedValue({
        likesUsed: 10,
        superLikesUsed: 0,
        boostsUsed: 0,
      });

      const result = await service.incrementLikes('u1');

      expect(result).toEqual({ success: false, remaining: 0 });
      expect(dailyLimitsRepository.save).not.toHaveBeenCalled();
    });

    it('always succeeds for premium users without touching counters', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser({ isPremium: true }));

      const result = await service.incrementLikes('u1');

      expect(result).toEqual({ success: true, remaining: -1 });
      expect(dailyLimitsRepository.findOne).not.toHaveBeenCalled();
      expect(dailyLimitsRepository.save).not.toHaveBeenCalled();
    });
  });

  describe('incrementSuperLikes', () => {
    it('allows the first super like of the day', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser());
      const limits = { likesUsed: 0, superLikesUsed: 0, boostsUsed: 0 };
      dailyLimitsRepository.findOne.mockResolvedValue(limits);

      const result = await service.incrementSuperLikes('u1');

      expect(result).toEqual({ success: true, remaining: 0 });
      expect(limits.superLikesUsed).toBe(1);
    });

    it('rejects the second super like for free users', async () => {
      usersRepository.findOne.mockResolvedValue(makeUser());
      dailyLimitsRepository.findOne.mockResolvedValue({
        likesUsed: 0,
        superLikesUsed: 1,
        boostsUsed: 0,
      });

      const result = await service.incrementSuperLikes('u1');

      expect(result).toEqual({ success: false, remaining: 0 });
    });
  });
});
