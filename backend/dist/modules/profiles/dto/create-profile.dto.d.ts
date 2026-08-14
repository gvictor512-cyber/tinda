export declare class CompatibilitySettingsDto {
    scheduleType?: string;
    cleanlinessLevel?: number;
    smokingPreference?: string;
    petsPreference?: string;
    personalityTraits?: string[];
    guestsFrequency?: string;
    cookingFrequency?: string;
    musicVolume?: string;
    workFromHome?: boolean;
}
export declare class CreateProfileDto {
    firstName: string;
    lastName?: string;
    age?: number;
    gender?: string;
    profession?: string;
    city: string;
    bio?: string;
    photos?: string[];
    budgetMin?: number;
    budgetMax?: number;
    preferredLocation?: string;
    languages?: string[];
    compatibilitySettings?: CompatibilitySettingsDto;
}
