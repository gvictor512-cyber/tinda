import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('profiles')
export class Profile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ name: 'first_name' })
  firstName: string;

  @Column({ name: 'last_name', nullable: true })
  lastName: string;

  @Column({ nullable: true })
  age: number;

  @Column({ nullable: true })
  gender: string;

  @Column({ nullable: true })
  profession: string;

  @Column()
  city: string;

  @Column({ type: 'text', nullable: true })
  bio: string;

  @Column({ name: 'profile_photo_url', nullable: true })
  profilePhotoUrl: string;

  @Column({ type: 'jsonb', default: '[]' })
  photos: string[];

  @Column({ name: 'budget_min', default: 300 })
  budgetMin: number;

  @Column({ name: 'budget_max', default: 1000 })
  budgetMax: number;

  @Column({ name: 'preferred_location', nullable: true })
  preferredLocation: string;

  @Column({ type: 'jsonb', default: '[]' })
  languages: string[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
