import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

import { PrismaService } from '../prisma/prisma.service.js';
import { LoginDto } from './dto/login.dto.js';
import { RegisterDto, RegisterRole } from './dto/register.dto.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const existingUser = await this.prisma.user.findUnique({
      where: {
        email: dto.email,
      },
    });

    if (existingUser) {
      throw new ConflictException('Email đã được sử dụng');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);

    const user = await this.prisma.$transaction(async (tx) => {
      const createdUser = await tx.user.create({
        data: {
          email: dto.email,
          passwordHash,
          role: dto.role,
        },
      });

      if (dto.role === RegisterRole.WORKER) {
        await tx.workerProfile.create({
          data: {
            userId: createdUser.id,
            fullName: dto.name,
          },
        });
      }

      if (dto.role === RegisterRole.EMPLOYER) {
        await tx.employerProfile.create({
          data: {
            userId: createdUser.id,
            companyName: dto.name,
          },
        });
      }

      return createdUser;
    });

    const accessToken = await this.generateToken(
      user.id,
      user.email,
      user.role,
    );

    return {
      message: 'Đăng ký thành công',
      accessToken,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        status: user.status,
      },
    };
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: {
        email: dto.email,
      },
    });

    if (!user) {
      throw new UnauthorizedException(
        'Email hoặc mật khẩu không đúng',
      );
    }

    if (!user.passwordHash) {
      throw new UnauthorizedException(
        'Tài khoản này không sử dụng mật khẩu. Vui lòng đăng nhập bằng Google.',
      );
    }

    const passwordMatched =
      await bcrypt.compare(
        dto.password,
        user.passwordHash,
      );

    if (!passwordMatched) {
      throw new UnauthorizedException(
        'Email hoặc mật khẩu không đúng',
      );
    }
    if (user.status === 'LOCKED') {
      throw new UnauthorizedException('Tài khoản đã bị khóa');
    }

    const accessToken = await this.generateToken(
      user.id,
      user.email,
      user.role,
    );

    return {
      message: 'Đăng nhập thành công',
      accessToken,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        status: user.status,
      },
    };
  }

  private async generateToken(
    userId: string,
    email: string,
    role: string,
  ) {
    return this.jwtService.signAsync({
      sub: userId,
      email,
      role,
    });
  }
}