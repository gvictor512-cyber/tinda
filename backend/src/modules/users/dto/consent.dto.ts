import { IsBoolean, IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class ConsentDto {
  @IsNotEmpty()
  @IsIn(['terms', 'privacy', 'cookies', 'marketing'])
  consentType: string;

  @IsNotEmpty()
  @IsBoolean()
  accepted: boolean;

  @IsOptional()
  @IsString()
  version?: string = '1.0';
}
