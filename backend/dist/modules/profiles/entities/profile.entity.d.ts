import { User } from '../../users/entities/user.entity';
export declare class Profile {
    id: string;
    userId: string;
    user: User;
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
}
