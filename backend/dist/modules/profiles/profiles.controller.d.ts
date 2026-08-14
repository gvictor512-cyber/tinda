import { ProfilesService } from './profiles.service';
import { CreateProfileDto } from './dto/create-profile.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
export declare class ProfilesController {
    private readonly profilesService;
    constructor(profilesService: ProfilesService);
    create(req: any, createProfileDto: CreateProfileDto): Promise<import("./entities/profile.entity").Profile>;
    findMyProfile(req: any): Promise<{
        compatibilitySettings: import("../compatibility/entities/compatibility-settings.entity").CompatibilitySettings;
        id: string;
        userId: string;
        user: import("../users/entities/user.entity").User;
        firstName: string;
        lastName: string;
        age: number;
        gender: string;
        profession: string;
        city: string;
        bio: string;
        profilePhotoUrl: string;
        photos: string[];
        budgetMin: number;
        budgetMax: number;
        preferredLocation: string;
        languages: string[];
        createdAt: Date;
        updatedAt: Date;
    }>;
    findOne(id: string): Promise<{
        compatibilitySettings: import("../compatibility/entities/compatibility-settings.entity").CompatibilitySettings;
        id: string;
        userId: string;
        user: import("../users/entities/user.entity").User;
        firstName: string;
        lastName: string;
        age: number;
        gender: string;
        profession: string;
        city: string;
        bio: string;
        profilePhotoUrl: string;
        photos: string[];
        budgetMin: number;
        budgetMax: number;
        preferredLocation: string;
        languages: string[];
        createdAt: Date;
        updatedAt: Date;
    }>;
    update(req: any, updateProfileDto: UpdateProfileDto): Promise<import("./entities/profile.entity").Profile>;
    delete(req: any): Promise<{
        message: string;
    }>;
    addPhoto(req: any, photoUrl: string): Promise<import("./entities/profile.entity").Profile>;
    removePhoto(req: any, index: string): Promise<import("./entities/profile.entity").Profile>;
}
