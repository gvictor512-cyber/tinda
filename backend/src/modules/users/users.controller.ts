import {
  Controller,
  Get,
  Delete,
  Post,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';
import { ConsentDto } from './dto/consent.dto';

@Controller('users')
@UseGuards(FirebaseAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  async getProfile(@Request() req) {
    return this.usersService.findByFirebaseUid(req.user.uid);
  }

  @Get('me/export')
  async exportData(@Request() req) {
    return this.usersService.exportData(req.user.uid);
  }

  @Delete('me')
  async deleteMe(@Request() req) {
    return this.usersService.deleteUser(req.user.uid);
  }

  @Post('me/consent')
  async logConsent(@Request() req, @Body() consentDto: ConsentDto) {
    return this.usersService.logConsent(req.user.uid, consentDto.consentType, consentDto.accepted, {
      ip: req.ip,
      userAgent: req.get('user-agent'),
      version: consentDto.version,
    });
  }
}
