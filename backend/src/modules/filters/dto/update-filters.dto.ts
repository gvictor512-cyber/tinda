import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsInt, IsArray, IsString, IsBoolean, Min, Max, IsEnum } from 'class-validator';

export class UpdateFiltersDto {
  @ApiProperty({ example: 18, required: false })
  @IsOptional()
  @IsInt()
  @Min(18)
  @Max(100)
  ageMin?: number;

  @ApiProperty({ example: 40, required: false })
  @IsOptional()
  @IsInt()
  @Min(18)
  @Max(100)
  ageMax?: number;

  @ApiProperty({ example: ['Madrid', 'Barcelona'], required: false })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  cities?: string[];

  @ApiProperty({ example: 300, required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  budgetMin?: number;

  @ApiProperty({ example: 1000, required: false })
  @IsOptional()
  @IsInt()
  @Min(0)
  budgetMax?: number;

  @ApiProperty({ example: ['no_fuma', 'fuma_fuera'], required: false })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  smokingPreferences?: string[];

  @ApiProperty({ example: ['me_encantan', 'tengo_mascotas'], required: false })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  petsPreferences?: string[];

  @ApiProperty({ example: true, required: false })
  @IsOptional()
  @IsBoolean()
  workFromHome?: boolean;

  @ApiProperty({ example: 'male', required: false })
  @IsOptional()
  @IsString()
  @IsEnum(['male', 'female', 'other'])
  gender?: string;

  @ApiProperty({ example: ['Español', 'Inglés'], required: false })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  languages?: string[];

  @ApiProperty({ example: ['Estudiante', 'Profesional'], required: false })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  userTypes?: string[];
}
