import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  async findByFirebaseUid(firebaseUid: string): Promise<User> {
    return this.usersRepository.findOne({ where: { firebaseUid } });
  }

  async create(firebaseUid: string, email: string): Promise<User> {
    const user = this.usersRepository.create({
      firebaseUid,
      email,
    });
    return this.usersRepository.save(user);
  }
}
