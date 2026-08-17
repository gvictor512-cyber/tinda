import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, IsString, IsOptional, Matches } from 'class-validator';

export class CreatePaymentIntentDto {
  @ApiProperty({ description: 'Amount in the smallest currency unit (cents)', example: 999 })
  @IsNotEmpty()
  @IsNumber()
  amount: number;

  @ApiProperty({ description: 'Currency code (ISO 4217)', example: 'eur' })
  @IsNotEmpty()
  @IsString()
  @Matches(/^[A-Z]{3}$/, { message: 'currency must be a 3-letter ISO 4217 code' })
  currency: string;

  @ApiProperty({ description: 'Plan or product identifier', example: 'premium_monthly' })
  @IsNotEmpty()
  @IsString()
  planId: string;

  @ApiProperty({ description: 'Existing Stripe customer ID', required: false })
  @IsOptional()
  @IsString()
  customerId?: string;
}
