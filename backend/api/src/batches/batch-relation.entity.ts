import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity({ name: 'batch_relations' })
export class BatchRelation {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'parent_batch_id', type: 'int' })
  parentBatchId: number;

  @Column({ name: 'child_batch_id', type: 'int' })
  childBatchId: number;

  @Column({ name: 'relation_type' })
  relationType: string;

  @Column({ type: 'numeric', precision: 14, scale: 3, nullable: true })
  quantity: number | null;

  @CreateDateColumn()
  createdAt: Date;
}
