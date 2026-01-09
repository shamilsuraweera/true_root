export enum UserRole {
  ADMIN = 'admin',
  FARMER = 'farmer',
  EXPORTER = 'exporter',
}

export class User {
  id: number;
  email: string;
  role: UserRole;
}
