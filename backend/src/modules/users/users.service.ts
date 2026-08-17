import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { ConsentLog } from './entities/consent-log.entity';
import { DataRequest } from './entities/data-request.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(ConsentLog)
    private consentLogRepository: Repository<ConsentLog>,
    @InjectRepository(DataRequest)
    private dataRequestRepository: Repository<DataRequest>,
  ) {}

  async findByFirebaseUid(firebaseUid: string): Promise<User> {
    return this.usersRepository.findOne({ where: { firebaseUid } });
  }

  async create(firebaseUid: string, email: string): Promise<User> {
    const user = this.usersRepository.create({
      firebaseUid,
      email,
    });
    return this.usersRepository.save(user);
  }

  async logConsent(
    firebaseUid: string,
    consentType: string,
    accepted: boolean,
    metadata?: { ip?: string; userAgent?: string; version?: string },
  ): Promise<{ user: User; log: ConsentLog }> {
    const user = await this.findByFirebaseUid(firebaseUid);
    if (!user) throw new NotFoundException('User not found');

    const fieldMap: Record<string, keyof User> = {
      terms: 'acceptedTermsAt',
      privacy: 'acceptedPrivacyAt',
      cookies: 'acceptedCookiesAt',
    };

    const field = fieldMap[consentType];
    if (field) {
      (user as any)[field] = accepted ? new Date() : null;
    }

    const consent = (user.consent || {}) as Record<string, unknown>;
    consent[consentType] = { accepted, at: new Date().toISOString() };
    user.consent = consent;

    await this.usersRepository.save(user);

    const log = this.consentLogRepository.create({
      userId: user.id,
      firebaseUid,
      consentType,
      accepted,
      version: metadata?.version || '1.0',
      ipAddress: metadata?.ip,
      userAgent: metadata?.userAgent,
    });

    return { user: await this.findByFirebaseUid(firebaseUid), log: await this.consentLogRepository.save(log) };
  }

  async exportData(firebaseUid: string): Promise<Record<string, unknown>> {
    const user = await this.findByFirebaseUid(firebaseUid);
    if (!user) throw new NotFoundException('User not found');

    const consents = await this.consentLogRepository.find({
      where: { firebaseUid },
      order: { createdAt: 'DESC' },
    });

    await this.dataRequestRepository.save(
      this.dataRequestRepository.create({
        userId: user.id,
        firebaseUid,
        requestType: 'export',
        status: 'completed',
        payload: { userEmail: user.email },
        completedAt: new Date(),
      }),
    );

    return {
      user: {
        id: user.id,
        firebaseUid: user.firebaseUid,
        email: user.email,
        displayName: user.displayName,
        phone: user.phone,
        birthDate: user.birthDate,
        isActive: user.isActive,
        isPremium: user.isPremium,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        consent: user.consent,
      },
      consents: consents.map((c) => ({
        consentType: c.consentType,
        accepted: c.accepted,
        version: c.version,
        createdAt: c.createdAt,
      })),
    };
  }

  async deleteUser(firebaseUid: string): Promise<DataRequest> {
    const user = await this.findByFirebaseUid(firebaseUid);
    if (!user) throw new NotFoundException('User not found');

    user.isActive = false;
    user.deletedAt = new Date();
    await this.usersRepository.save(user);

    const request = this.dataRequestRepository.create({
      userId: user.id,
      firebaseUid,
      requestType: 'deletion',
      status: 'completed',
      completedAt: new Date(),
    });

    return this.dataRequestRepository.save(request);
  }
}
