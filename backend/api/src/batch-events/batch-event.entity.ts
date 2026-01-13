import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

export enum BatchEventType {
  CREATED = 'CREATED',
  QUANTITY_CHANGED = 'QUANTITY_CHANGED',
  STATUS_CHANGED = 'STATUS_CHANGED',
  GRADE_CHANGED = 'GRADE_CHANGED',
  DISQUALIFIED = 'DISQUALIFIED',
}

@Entity({ name: 'batch_events' })
export class BatchEvent {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int' })
  batchId: number;

  @Column({ type: 'varchar', length: 50 })
  type: BatchEventType;

  @Column({ type: 'varchar', length: 255 })
  description: string;

  @CreateDateColumn()
  createdAt: Date;
}
