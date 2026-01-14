import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

export enum OwnershipRequestStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
}

@Entity({ name: 'ownership_requests' })
export class OwnershipRequest {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'batch_id', type: 'int' })
  batchId: number;

  @Column({ name: 'requester_id', type: 'int' })
  requesterId: number;

  @Column({ name: 'owner_id', type: 'int' })
  ownerId: number;

  @Column({ type: 'numeric', precision: 14, scale: 3 })
  quantity: number;

  @Column({ type: 'varchar', length: 20 })
  status: OwnershipRequestStatus;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  @CreateDateColumn()
  createdAt: Date;
}
