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
  SPLIT = 'SPLIT',
  MERGED = 'MERGED',
  TRANSFORMED = 'TRANSFORMED',
  ARCHIVED = 'ARCHIVED',
  TRANSFERRED = 'TRANSFERRED',
}

@Entity({ name: 'batch_events' })
export class BatchEvent {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'batch_id', type: 'int' })
  batchId: number;

  @Column({ type: 'varchar', length: 50 })
  type: BatchEventType;

  @Column({ name: 'stage_id', type: 'int', nullable: true })
  stageId: number | null;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ name: 'quantity_before', type: 'numeric', precision: 14, scale: 3, nullable: true })
  quantityBefore: number | null;

  @Column({ name: 'quantity_after', type: 'numeric', precision: 14, scale: 3, nullable: true })
  quantityAfter: number | null;

  @Column({ name: 'status_before', type: 'varchar', length: 50, nullable: true })
  statusBefore: string | null;

  @Column({ name: 'status_after', type: 'varchar', length: 50, nullable: true })
  statusAfter: string | null;

  @Column({ name: 'grade_before', type: 'varchar', length: 50, nullable: true })
  gradeBefore: string | null;

  @Column({ name: 'grade_after', type: 'varchar', length: 50, nullable: true })
  gradeAfter: string | null;

  @Column({ name: 'actor_user_id', type: 'int', nullable: true })
  actorUserId: number | null;

  @Column({ type: 'jsonb', nullable: true })
  metadata: Record<string, unknown> | null;

  @CreateDateColumn()
  createdAt: Date;
}
