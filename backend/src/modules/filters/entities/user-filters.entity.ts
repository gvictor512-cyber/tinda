import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('user_filters')
export class UserFilters {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ name: 'age_min', default: 18 })
  ageMin: number;

  @Column({ name: 'age_max', default: 40 })
  ageMax: number;

  @Column({ type: 'jsonb', default: '[]' })
  cities: string[];

  @Column({ name: 'budget_min', default: 300 })
  budgetMin: number;

  @Column({ name: 'budget_max', default: 1000 })
  budgetMax: number;

  @Column({ type: 'jsonb', default: '[]' })
  smokingPreferences: string[];

  @Column({ type: 'jsonb', default: '[]' })
  petsPreferences: string[];

  @Column({ name: 'work_from_home', nullable: true })
  workFromHome: boolean;

  @Column({ nullable: true })
  gender: string;

  @Column({ type: 'jsonb', default: '[]' })
  languages: string[];

  @Column({ type: 'jsonb', default: '[]' })
  userTypes: string[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
