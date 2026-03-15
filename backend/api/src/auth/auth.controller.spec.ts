import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { UserRole } from './auth.types';

describe('AuthController', () => {
  const loginWithPassword = jest.fn();
  const register = jest.fn();
  const mockAuthService = {
    loginWithPassword,
    register,
  } as unknown as AuthService;

  const controller = new AuthController(mockAuthService);

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('delegates login to service', async () => {
    const dto: LoginDto = {
      email: 'user@example.com',
      password: 'secret',
    };

    await controller.login(dto);

    expect(loginWithPassword).toHaveBeenCalledWith(dto.email, dto.password);
  });

  it('delegates register to service', async () => {
    const dto: RegisterDto = {
      email: 'new@example.com',
      password: 'secret',
      role: UserRole.FARMER,
      name: 'Farmer One',
    };

    await controller.register(dto);

    expect(register).toHaveBeenCalledWith(
      dto.email,
      dto.password,
      dto.role,
      dto.name,
    );
  });
});
