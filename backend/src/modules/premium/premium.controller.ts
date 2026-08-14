import { Controller, Get, Post, Body, UseGuards, Request, HttpCode, HttpStatus } from '@nestjs/common';
import { PremiumService } from './premium.service';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';

@Controller('premium')
@UseGuards(FirebaseAuthGuard)
export class PremiumController {
  constructor(private readonly premiumService: PremiumService) {}

  @Get('status')
  async getPremiumStatus(@Request() req) {
    return this.premiumService.getPremiumStatus(req.user.uid);
  }

  @Get('features')
  async getPremiumFeatures() {
    return this.premiumService.getPremiumFeatures();
  }

  @Post('subscribe')
  @HttpCode(HttpStatus.OK)
  async subscribe(@Request() req, @Body() createSubscriptionDto: CreateSubscriptionDto) {
    return this.premiumService.createSubscription(req.user.uid, createSubscriptionDto);
  }

  @Post('cancel')
  @HttpCode(HttpStatus.OK)
  async cancelSubscription(@Request() req) {
    return this.premiumService.cancelSubscription(req.user.uid);
  }

  @Get('daily-limits')
  async getDailyLimits(@Request() req) {
    return this.premiumService.getDailyLimits(req.user.uid);
  }

  @Post('boost')
  @HttpCode(HttpStatus.OK)
  async boostProfile(@Request() req) {
    return this.premiumService.boostProfile(req.user.uid);
  }
}
