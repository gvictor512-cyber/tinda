import { FiltersService } from './filters.service';
import { UpdateFiltersDto } from './dto/update-filters.dto';
export declare class FiltersController {
    private readonly filtersService;
    constructor(filtersService: FiltersService);
    getMyFilters(req: any): Promise<import("./entities/user-filters.entity").UserFilters>;
    updateFilters(req: any, updateFiltersDto: UpdateFiltersDto): Promise<import("./entities/user-filters.entity").UserFilters>;
    resetFilters(req: any): Promise<import("./entities/user-filters.entity").UserFilters>;
}
