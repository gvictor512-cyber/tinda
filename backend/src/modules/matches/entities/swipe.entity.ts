import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('swipes')
export class Swipe {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'swiper_id' })
  swiperId: string;

  @Column({ name: 'swiped_id' })
  swipedId: string;

  @Column({ name: 'swipe_type' })
  swipeType: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
