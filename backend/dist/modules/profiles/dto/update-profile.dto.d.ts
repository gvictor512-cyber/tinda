import { CreateProfileDto } from './create-profile.dto';
declare const UpdateProfileDto_base: import("@nestjs/common").Type<Partial<Omit<CreateProfileDto, "firstName" | "city">>>;
export declare class UpdateProfileDto extends UpdateProfileDto_base {
}
export {};
