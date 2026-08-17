import { UsersService } from './users.service';
import { ConsentDto } from './dto/consent.dto';
export declare class UsersController {
    private readonly usersService;
    constructor(usersService: UsersService);
    getProfile(req: any): Promise<import("./entities/user.entity").User>;
    exportData(req: any): Promise<Record<string, unknown>>;
    deleteMe(req: any): Promise<import("./entities/data-request.entity").DataRequest>;
    logConsent(req: any, consentDto: ConsentDto): Promise<{
        user: import("./entities/user.entity").User;
        log: import("./entities/consent-log.entity").ConsentLog;
    }>;
}
