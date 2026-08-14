import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, Matches } from 'class-validator';

export class VerifyPhoneDto {
  @ApiProperty({
    description: 'Phone number',
    example: '+34612345678',
  })
  @IsNotEmpty()
  @IsString()
  @Matches(/^\+?[1-9]\d{1,14}$/)
  phoneNumber: string;

  @ApiProperty({
    description: 'SMS verification code',
    example: '123456',
  })
  @IsNotEmpty()
  @IsString()
  code: string;
}
