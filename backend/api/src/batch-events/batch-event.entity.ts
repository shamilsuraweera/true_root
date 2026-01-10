import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
} from 'typeorm';
import { Batch } from '../batches/batch.entity';

export enum BatchEventType {
  CREATED = 'created',
  QUANTITY_CHANGED = 'quantity_changed',
  STATUS_CHANGED = 'status_changed',
  GRADE_CHANGED = 'grade_changed',
  DISQUALIFIED = 'disqualified',
  MERGED = 'merged',
  SPLIT = 'split',
  TRANSFORMED = 'transformed',
}

@Entity('batch_events')
export class BatchEvent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Batch, { nullable: false })
  batch: Batch;

  @Column({
    type: 'enum',
    enum: BatchEventType,
  })
  type: BatchEventType;

  @Column('jsonb', { nullable: true })
  metadata: Record<string, any>;

  @CreateDateColumn()
  createdAt: Date;
}
