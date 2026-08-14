import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsEnum, IsUUID } from 'class-validator';

export class SwipeDto {
  @ApiProperty({
    description: 'Target user ID',
    example: '123e4567-e89b-12d3-a456-426614174000',
  })
  @IsNotEmpty()
  @IsUUID()
  targetUserId: string;

  @ApiProperty({
    description: 'Swipe type',
    enum: ['like', 'dislike', 'super_like'],
    example: 'like',
  })
  @IsNotEmpty()
  @IsEnum(['like', 'dislike', 'super_like'])
  type: 'like' | 'dislike' | 'super_like';
}
