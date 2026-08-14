import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class VerifySelfieDto {
  @ApiProperty({
    description: 'Selfie image URL',
    example: 'https://storage.example.com/selfies/abc123.jpg',
  })
  @IsNotEmpty()
  @IsString()
  selfieUrl: string;
}
