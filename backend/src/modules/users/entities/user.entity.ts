import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  firebaseUid: string;

  @Column({ unique: true })
  email: string;

  @Column({ nullable: true })
  displayName: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ type: 'date', nullable: true })
  birthDate: Date;

  @Column({ type: 'jsonb', default: {} })
  consent: Record<string, unknown>;

  @Column({ default: true })
  isActive: boolean;

  @Column({ default: false })
  isPremium: boolean;

  @Column({ type: 'timestamp', nullable: true })
  premiumExpiresAt: Date;

  @Column({ default: false })
  isVerified: boolean;

  @Column({ type: 'timestamp', nullable: true })
  deletedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  acceptedTermsAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  acceptedPrivacyAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  acceptedCookiesAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
