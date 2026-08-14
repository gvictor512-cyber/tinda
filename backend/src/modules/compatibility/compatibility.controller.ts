import { Controller, Get, Post, Body, UseGuards, Request, Param, ParseUUIDPipe, HttpCode, HttpStatus } from '@nestjs/common';
import { CompatibilityService, CompatibilityResult, FactorResult } from './compatibility.service';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';

@Controller('compatibility')
@UseGuards(FirebaseAuthGuard)
export class CompatibilityController {
  constructor(private readonly compatibilityService: CompatibilityService) {}

  @Post('calculate')
  @HttpCode(HttpStatus.OK)
  async calculateCompatibility(@Request() req, @Body('targetUserId') targetUserId: string): Promise<CompatibilityResult> {
    return this.compatibilityService.calculateCompatibility(req.user.uid, targetUserId);
  }

  @Get('score/:userId')
  async getCompatibilityScore(@Request() req, @Param('userId', ParseUUIDPipe) userId: string): Promise<CompatibilityResult> {
    return this.compatibilityService.calculateCompatibility(req.user.uid, userId);
  }

  @Get('explanation/:userId')
  async getCompatibilityExplanation(@Request() req, @Param('userId', ParseUUIDPipe) userId: string): Promise<{ score: number; explanation: string; factors: FactorResult[] }> {
    const result = await this.compatibilityService.calculateCompatibility(req.user.uid, userId);
    return {
      score: result.score,
      explanation: result.explanation,
      factors: result.factors,
    };
  }

  @Get('recommendations')
  async getRecommendations(@Request() req) {
    return this.compatibilityService.getRecommendations(req.user.uid);
  }
}
