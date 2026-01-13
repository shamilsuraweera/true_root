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

  @Column({ nullable: true })
  name: string | null;

  @Column({ nullable: true })
  organization: string | null;

  @Column({ nullable: true })
  location: string | null;

  @Column({ name: 'account_type', nullable: true })
  accountType: string | null;

  @Column({ type: 'jsonb', nullable: true })
  members: string[] | null;

  @CreateDateColumn()
  createdAt: Date;
}
