import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsEnum, IsBoolean, IsString, IsOptional } from 'class-validator';

export class CreateSubscriptionDto {
  @ApiProperty({
    description: 'Subscription plan type',
    enum: ['premium_monthly', 'premium_yearly'],
    example: 'premium_monthly',
  })
  @IsNotEmpty()
  @IsEnum(['premium_monthly', 'premium_yearly'])
  planType: 'premium_monthly' | 'premium_yearly';

  @ApiProperty({
    description: 'Auto renew subscription',
    example: false,
    required: false,
  })
  @IsOptional()
  @IsBoolean()
  autoRenew?: boolean;

  @ApiProperty({
    description: 'Payment method',
    example: 'credit_card',
    required: false,
  })
  @IsOptional()
  @IsString()
  paymentMethod?: string;
}
