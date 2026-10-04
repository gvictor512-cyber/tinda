import { IsIn, IsInt, IsNotEmpty, IsOptional, IsString, Length, Min } from 'class-validator';

export class SendReceiptDto {
  @IsString()
  @IsNotEmpty()
  productId: string;

  @IsString()
  @IsNotEmpty()
  transactionId: string;

  @IsOptional()
  @IsString()
  productName?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  amountCents?: number;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @IsOptional()
  @IsIn(['ios', 'android', 'web'])
  platform?: string;
}
