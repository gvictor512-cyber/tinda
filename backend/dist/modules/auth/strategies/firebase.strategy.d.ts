import { Strategy } from 'passport-custom';
import { Repository } from 'typeorm';
import { User } from '../../users/entities/user.entity';
declare const FirebaseStrategy_base: new (...args: any[]) => Strategy;
export declare class FirebaseStrategy extends FirebaseStrategy_base {
    private readonly usersRepository;
    constructor(usersRepository: Repository<User>);
    validate(req: any): Promise<{
        uid: string;
        email: string;
        emailVerified: boolean;
        role: string;
    }>;
    private extractTokenFromHeader;
}
export {};
