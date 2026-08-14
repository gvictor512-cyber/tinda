import { Repository } from 'typeorm';
import { UserFilters } from './entities/user-filters.entity';
import { User } from '../users/entities/user.entity';
import { UpdateFiltersDto } from './dto/update-filters.dto';
export declare class FiltersService {
    private userFiltersRepository;
    private usersRepository;
    constructor(userFiltersRepository: Repository<UserFilters>, usersRepository: Repository<User>);
    getUserFilters(firebaseUid: string): Promise<UserFilters>;
    updateFilters(firebaseUid: string, updateFiltersDto: UpdateFiltersDto): Promise<UserFilters>;
    resetFilters(firebaseUid: string): Promise<UserFilters>;
}
