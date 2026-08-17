import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { ConsentLog } from './entities/consent-log.entity';
import { DataRequest } from './entities/data-request.entity';
export declare class UsersService {
    private usersRepository;
    private consentLogRepository;
    private dataRequestRepository;
    constructor(usersRepository: Repository<User>, consentLogRepository: Repository<ConsentLog>, dataRequestRepository: Repository<DataRequest>);
    findByFirebaseUid(firebaseUid: string): Promise<User>;
    create(firebaseUid: string, email: string): Promise<User>;
    logConsent(firebaseUid: string, consentType: string, accepted: boolean, metadata?: {
        ip?: string;
        userAgent?: string;
        version?: string;
    }): Promise<{
        user: User;
        log: ConsentLog;
    }>;
    exportData(firebaseUid: string): Promise<Record<string, unknown>>;
    deleteUser(firebaseUid: string): Promise<DataRequest>;
}
