import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('verification')
export class Verification {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ name: 'email_verified', default: false })
  emailVerified: boolean;

  @Column({ name: 'email_verified_at', type: 'timestamp', nullable: true })
  emailVerifiedAt: Date;

  @Column({ name: 'phone_verified', default: false })
  phoneVerified: boolean;

  @Column({ name: 'phone_verified_at', type: 'timestamp', nullable: true })
  phoneVerifiedAt: Date;

  @Column({ name: 'selfie_verified', default: false })
  selfieVerified: boolean;

  @Column({ name: 'selfie_verified_at', type: 'timestamp', nullable: true })
  selfieVerifiedAt: Date;

  @Column({ name: 'document_verified', default: false })
  documentVerified: boolean;

  @Column({ name: 'document_verified_at', type: 'timestamp', nullable: true })
  documentVerifiedAt: Date;

  @Column({ name: 'document_url', nullable: true })
  documentUrl: string;

  @Column({ name: 'selfie_url', nullable: true })
  selfieUrl: string;

  @Column({ name: 'selfie_submitted_at', type: 'timestamp', nullable: true })
  selfieSubmittedAt: Date;

  @Column({ name: 'is_verified', default: false })
  isVerified: boolean;

  @Column({ name: 'verification_level' })
  verificationLevel: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
