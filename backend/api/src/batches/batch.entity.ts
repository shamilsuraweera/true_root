import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  CreateDateColumn,
} from 'typeorm';
import { Product } from '../products/product.entity';

export enum BatchStatus {
  CREATED = 'created',
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
  DISQUALIFIED = 'disqualified',
}

export enum BatchGrade {
  A = 'A',
  B = 'B',
  C = 'C',
}

@Entity('batches')
export class Batch {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Product, { nullable: false })
  product: Product;

  @Column('decimal')
  quantity: number;

  @Column({
    type: 'enum',
    enum: BatchStatus,
    default: BatchStatus.CREATED,
  })
  status: BatchStatus;

  @Column({
    type: 'enum',
    enum: BatchGrade,
  })
  grade: BatchGrade;

  @CreateDateColumn()
  createdAt: Date;
}
