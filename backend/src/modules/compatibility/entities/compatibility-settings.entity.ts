import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('compatibility_settings')
export class CompatibilitySettings {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ name: 'schedule_type', nullable: true })
  scheduleType: string;

  @Column({ name: 'cleanliness_level', nullable: true })
  cleanlinessLevel: number;

  @Column({ name: 'smoking_preference', nullable: true })
  smokingPreference: string;

  @Column({ name: 'pets_preference', nullable: true })
  petsPreference: string;

  @Column({ type: 'jsonb', default: '[]' })
  personalityTraits: string[];

  @Column({ name: 'guests_frequency', nullable: true })
  guestsFrequency: string;

  @Column({ name: 'cooking_frequency', nullable: true })
  cookingFrequency: string;

  @Column({ name: 'music_volume', nullable: true })
  musicVolume: string;

  @Column({ name: 'work_from_home', default: false })
  workFromHome: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
