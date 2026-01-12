import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('batch_events')
export class BatchEvent {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  batchId: string;

  @Column()
  type: string;

  @Column()
  description: string;

  @CreateDateColumn()
  createdAt: Date;
}
