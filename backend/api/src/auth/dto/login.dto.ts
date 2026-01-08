import { UserRole } from '../auth.types';

export class LoginDto {
  userId: number;
  role: UserRole;
}
