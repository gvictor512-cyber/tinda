import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsOptional, IsInt, Min, Max } from 'class-validator';

export class CreateGroupDto {
  @ApiProperty({ example: 'Grupo piso Madrid' })
  @IsNotEmpty()
  @IsString()
  name: string;

  @ApiProperty({ example: 'Buscamos compañeros para piso en el centro', required: false })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 4, required: false })
  @IsOptional()
  @IsInt()
  @Min(2)
  @Max(10)
  maxMembers?: number;
}
