import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('batches')
export class Batch {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'product_id' })
  productId: number;

  @Column({ name: 'batch_code', unique: true })
  batchCode: string;

  @Column({ type: 'numeric', precision: 14, scale: 3 })
  quantity: number;

  @Column({ default: 'kg' })
  unit: string;

  @Column({ type: 'varchar', length: 50 })
  status: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  grade: string | null;

  @Column({ name: 'stage_id', type: 'int', nullable: true })
  stageId: number | null;

  @Column({ name: 'qr_payload', nullable: true, unique: true })
  qrPayload: string | null;

  @Column({ name: 'is_disqualified', default: false })
  isDisqualified: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
