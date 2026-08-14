import { Controller, Get, Post, Body, UseGuards, Request, Param, ParseUUIDPipe, HttpCode, HttpStatus } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';

@Controller('notifications')
@UseGuards(FirebaseAuthGuard)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  async getNotifications(@Request() req) {
    const user = req.user;
    // TODO: Get user ID from Firebase UID
    return this.notificationsService.getUserNotifications(user.uid);
  }

  @Post(':id/read')
  @HttpCode(HttpStatus.OK)
  async markAsRead(@Param('id', ParseUUIDPipe) id: string) {
    return this.notificationsService.markAsRead(id);
  }

  @Post('read-all')
  @HttpCode(HttpStatus.OK)
  async markAllAsRead(@Request() req) {
    const user = req.user;
    // TODO: Get user ID from Firebase UID
    return this.notificationsService.markAllAsRead(user.uid);
  }
}
