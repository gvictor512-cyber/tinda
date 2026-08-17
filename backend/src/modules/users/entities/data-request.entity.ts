import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('data_requests')
export class DataRequest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  userId: string;

  @Column()
  firebaseUid: string;

  @Column()
  requestType: 'export' | 'deletion';

  @Column({ default: 'pending' })
  status: 'pending' | 'completed' | 'rejected';

  @Column({ type: 'jsonb', nullable: true })
  payload: Record<string, unknown>;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  completedAt: Date;
}
