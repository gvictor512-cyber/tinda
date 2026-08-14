import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class SetupSubscriptionDto {
  @ApiProperty({ description: 'Stripe Customer ID', example: 'cus_...' })
  @IsNotEmpty()
  @IsString()
  customerId: string;

  @ApiProperty({ description: 'Stripe Price ID', example: 'price_1O...' })
  @IsNotEmpty()
  @IsString()
  priceId: string;

  @ApiProperty({ description: 'Stripe Payment Method ID', example: 'pm_1O...' })
  @IsNotEmpty()
  @IsString()
  paymentMethodId: string;
}
