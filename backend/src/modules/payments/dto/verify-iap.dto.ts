import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class VerifyIapDto {
  @ApiProperty({ description: 'Product/plan identifier', example: 'premium_monthly' })
  @IsString()
  @IsNotEmpty()
  productId: string;

  @ApiProperty({ description: 'Store transaction identifier' })
  @IsString()
  @IsNotEmpty()
  transactionId: string;

  @ApiProperty({ description: 'Purchase platform', enum: ['ios', 'android', 'internal'] })
  @IsIn(['ios', 'android', 'internal'])
  platform: string;

  @ApiProperty({
    description:
      'App Store receipt (base64) or Google Play purchase token. ' +
      'Not required for platform=internal.',
    required: false,
  })
  @IsOptional()
  @IsString()
  verificationData?: string;
}
