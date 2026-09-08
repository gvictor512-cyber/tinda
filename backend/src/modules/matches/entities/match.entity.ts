import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from 'typeorm';

@Entity('matches')
@Index(['user1Id', 'user2Id'])
@Index(['isActive', 'createdAt'])
export class Match {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user1_id' })
  user1Id: string;

  @Column({ name: 'user2_id' })
  user2Id: string;

  @Column({ name: 'compatibility_score' })
  compatibilityScore: number;

  @Column({ name: 'compatibility_explanation', type: 'text', nullable: true })
  compatibilityExplanation: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @Column({ default: true })
  isActive: boolean;
}
