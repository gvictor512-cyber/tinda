import { Entity, PrimaryGeneratedColumn, Column,CreateDateColumn } from 'typeorm';

@Entity('daily_limits')
export class DailyLimits {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ type: 'date' })
  date: Date;

  @Column({ name: 'likes_used', default: 0 })
  likesUsed: number;

  @Column({ name: 'super_likes_used', default: 0 })
  superLikesUsed: number;

  @Column({ name: 'boosts_used', default: 0 })
  boostsUsed: number;
}
