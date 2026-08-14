import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsInt, IsArray, IsEnum, Min, Max, IsBoolean } from 'class-validator';

export class CompatibilitySettingsDto {
  @ApiProperty({ example: 'madrugador', required: false })
  @IsString()
  @IsOptional()
  @IsEnum(['madrugador', 'nocturno', 'trabajo_remoto', 'turnos', 'estudiante'])
  scheduleType?: string;

  @ApiProperty({ example: 4, required: false })
  @IsInt()
  @IsOptional()
  @Min(1)
  @Max(5)
  cleanlinessLevel?: number;

  @ApiProperty({ example: 'no_fuma', required: false })
  @IsString()
  @IsOptional()
  @IsEnum(['no_fuma', 'fuma_fuera', 'fuma_dentro'])
  smokingPreference?: string;

  @ApiProperty({ example: 'me_encantan', required: false })
  @IsString()
  @IsOptional()
  @IsEnum(['me_encantan', 'tengo_mascotas', 'no_quiero_mascotas', 'soy_alergico'])
  petsPreference?: string;

  @ApiProperty({ example: ['deportista', 'tranquilo'], required: false })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  personalityTraits?: string[];

  @ApiProperty({ example: 'a_veces', required: false })
  @IsString()
  @IsOptional()
  @IsEnum(['nunca', 'a_veces', 'frecuentemente'])
  guestsFrequency?: string;

  @ApiProperty({ example: 'ocasionalmente', required: false })
  @IsString()
  @IsOptional()
  @IsEnum(['nunca', 'ocasionalmente', 'todos_los_dias'])
  cookingFrequency?: string;

  @ApiProperty({ example: 'a_veces', required: false })
  @IsString()
  @IsOptional()
  @IsEnum(['nunca', 'a_veces', 'mucho'])
  musicVolume?: string;

  @ApiProperty({ example: true, required: false })
  @IsOptional()
  @IsBoolean()
  workFromHome?: boolean;
}

export class CreateProfileDto {
  @ApiProperty({ example: 'Juan' })
  @IsString()
  @IsNotEmpty()
  firstName: string;

  @ApiProperty({ example: 'García', required: false })
  @IsString()
  @IsOptional()
  lastName?: string;

  @ApiProperty({ example: 25, required: false })
  @IsInt()
  @IsOptional()
  @Min(18)
  @Max(100)
  age?: number;

  @ApiProperty({ example: 'male', required: false })
  @IsString()
  @IsOptional()
  @IsEnum(['male', 'female', 'other'])
  gender?: string;

  @ApiProperty({ example: 'Estudiante', required: false })
  @IsString()
  @IsOptional()
  profession?: string;

  @ApiProperty({ example: 'Madrid' })
  @IsString()
  @IsNotEmpty()
  city: string;

  @ApiProperty({ example: 'Busco compañeros tranquilos y ordenados', required: false })
  @IsString()
  @IsOptional()
  bio?: string;

  @ApiProperty({ example: ['https://example.com/photo1.jpg'], required: false })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  photos?: string[];

  @ApiProperty({ example: 400, required: false })
  @IsInt()
  @IsOptional()
  @Min(300)
  budgetMin?: number;

  @ApiProperty({ example: 600, required: false })
  @IsInt()
  @IsOptional()
  @Min(300)
  budgetMax?: number;

  @ApiProperty({ example: 'Centro', required: false })
  @IsString()
  @IsOptional()
  preferredLocation?: string;

  @ApiProperty({ example: ['Español', 'Inglés'], required: false })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  languages?: string[];

  @ApiProperty({ required: false })
  @IsOptional()
  compatibilitySettings?: CompatibilitySettingsDto;
}
