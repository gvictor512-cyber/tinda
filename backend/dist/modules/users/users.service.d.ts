import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
export declare class UsersService {
    private usersRepository;
    constructor(usersRepository: Repository<User>);
    findByFirebaseUid(firebaseUid: string): Promise<User>;
    create(firebaseUid: string, email: string): Promise<User>;
}
