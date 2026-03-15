import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity({ name: 'products' })
export class Product {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text', unique: true })
  name: string;

  @Column({ name: 'owner_id', type: 'int', nullable: true })
  ownerId: number | null;

  @Column({ name: 'is_merged_product', default: false })
  isMergedProduct: boolean;

  @Column({
    name: 'source_product_ids',
    type: 'int',
    array: true,
    nullable: true,
  })
  sourceProductIds: number[] | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
