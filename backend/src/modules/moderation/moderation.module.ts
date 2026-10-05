import { Module } from '@nestjs/common';
import {
  Controller,
  Post,
  Get,
  Body,
  Request,
  UseGuards,
  HttpCode,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { admin } from '../../common/config/firebase.config';
import { IsIn, IsNotEmpty, IsOptional, IsString, IsUrl } from 'class-validator';
import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

class FlagContentDto {
  @IsIn(['photo', 'bio', 'message', 'profile'])
  type: 'photo' | 'bio' | 'message' | 'profile';

  @IsString()
  @IsNotEmpty()
  targetUserId: string;

  @IsOptional()
  @IsUrl()
  url?: string;

  @IsOptional()
  @IsString()
  text?: string;
}

@Injectable()
export class ModerationService {
  private readonly logger = new Logger(ModerationService.name);

  constructor(private readonly configService: ConfigService) {}

  /**
   * Automatic check against Sightengine when credentials are configured.
   * Returns a score 0..1 (1 = safe). When not configured returns null and
   * the item simply lands in the review queue.
   */
  async checkImage(url: string): Promise<number | null> {
    const apiUser = this.configService.get<string>('SIGHTENGINE_API_USER');
    const apiSecret = this.configService.get<string>('SIGHTENGINE_API_SECRET');
    if (!apiUser || !apiSecret) return null;

    try {
      const params = new URLSearchParams({
        url,
        models: 'nudity-2.0,violence,offensive',
        api_user: apiUser,
        api_secret: apiSecret,
      });
      const res = await fetch(
        `https://api.sightengine.com/1.0/check.json?${params}`,
      );
      const body = (await res.json()) as any;
      if (body.status !== 'success') return null;

      const nudity =
        body.nudity?.sexual_activity ??
        body.nudity?.sexual_display ??
        body.nudity?.erotica ??
        0;
      const violence = body.violence?.prob ?? 0;
      const offensive = body.offensive?.prob ?? 0;
      return Math.max(0, 1 - Math.max(nudity, violence, offensive));
    } catch (e) {
      this.logger.warn(`Sightengine check failed: ${e}`);
      return null;
    }
  }

  async flag(reporterId: string, dto: FlagContentDto) {
    let score: number | null = null;
    if (dto.type === 'photo' && dto.url) {
      score = await this.checkImage(dto.url);
    }

    const entry = {
      reporterId,
      targetUserId: dto.targetUserId,
      type: dto.type,
      url: dto.url ?? null,
      text: dto.text?.slice(0, 2000) ?? null,
      autoScore: score,
      autoRejected: score !== null && score < 0.4,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await admin.firestore().collection('moderation_queue').add(entry);

    return {
      queued: true,
      autoRejected: entry.autoRejected,
    };
  }

  async listPending(limit = 50) {
    const snap = await admin
      .firestore()
      .collection('moderation_queue')
      .where('status', '==', 'pending')
      .limit(limit)
      .get();
    return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  }

  async resolve(id: string, action: 'approve' | 'reject') {
    await admin.firestore().collection('moderation_queue').doc(id).update({
      status: action === 'approve' ? 'resolved_ok' : 'resolved_removed',
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { id, action };
  }
}

@ApiTags('moderation')
@Controller('moderation')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class ModerationController {
  constructor(private readonly moderationService: ModerationService) {}

  /** Report/flag content; photos also get an automated score when configured. */
  @Post('flag')
  @HttpCode(HttpStatus.OK)
  async flag(@Request() req, @Body() dto: FlagContentDto) {
    return this.moderationService.flag(req.user.uid, dto);
  }

  @Get('queue')
  @UseGuards(RolesGuard)
  @Roles('admin')
  async listPending() {
    return this.moderationService.listPending();
  }

  @Post('resolve')
  @UseGuards(RolesGuard)
  @Roles('admin')
  async resolve(@Body() body: { id: string; action: 'approve' | 'reject' }) {
    return this.moderationService.resolve(body.id, body.action);
  }
}

@Module({
  controllers: [ModerationController],
  providers: [ModerationService],
})
export class ModerationModule {}
