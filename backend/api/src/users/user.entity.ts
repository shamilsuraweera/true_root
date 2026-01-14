import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';
import { UserRole } from '../auth/auth.types';

@Entity({ name: 'users' })
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  email: string;

  @Column()
  role: UserRole;

  @Column({ type: 'text', nullable: true })
  name: string | null;

  @Column({ type: 'text', nullable: true })
  organization: string | null;

  @Column({ type: 'text', nullable: true })
  location: string | null;

  @Column({ name: 'account_type', type: 'text', nullable: true })
  accountType: string | null;

  @Column({ type: 'jsonb', nullable: true })
  members: string[] | null;

  @CreateDateColumn()
  createdAt: Date;
}
