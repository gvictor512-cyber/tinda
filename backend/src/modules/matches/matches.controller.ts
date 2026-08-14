import { Controller, Get, Post, Delete, Body, UseGuards, Request, Param, ParseUUIDPipe, HttpCode, HttpStatus } from '@nestjs/common';
import { MatchesService } from './matches.service';
import { SwipeDto } from './dto/swipe.dto';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';

@Controller('matches')
@UseGuards(FirebaseAuthGuard)
export class MatchesController {
  constructor(private readonly matchesService: MatchesService) {}

  @Post('swipe')
  @HttpCode(HttpStatus.OK)
  async swipe(@Request() req, @Body() swipeDto: SwipeDto) {
    return this.matchesService.handleSwipe(req.user.uid, swipeDto);
  }

  @Get()
  async getMyMatches(@Request() req) {
    return this.matchesService.getUserMatches(req.user.uid);
  }

  @Get(':matchId')
  async getMatch(@Request() req, @Param('matchId', ParseUUIDPipe) matchId: string) {
    return this.matchesService.getMatch(req.user.uid, matchId);
  }

  @Delete(':matchId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async unmatch(@Request() req, @Param('matchId', ParseUUIDPipe) matchId: string) {
    return this.matchesService.unmatch(req.user.uid, matchId);
  }

  @Get('pending/likes')
  async getPendingLikes(@Request() req) {
    return this.matchesService.getPendingLikes(req.user.uid);
  }
}
