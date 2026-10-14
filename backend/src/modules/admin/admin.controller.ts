import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';

@ApiTags('admin')
@Controller('admin')
@UseGuards(FirebaseAuthGuard, RolesGuard)
@Roles('admin')
@ApiBearerAuth()
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  /** Clamps pagination params to sane bounds (take ≤ 100, skip ≥ 0). */
  private static takeSkip(take: unknown, skip: unknown): [number, number] {
    const t = Number(take);
    const s = Number(skip);
    return [
      Number.isFinite(t) ? Math.min(Math.max(t, 1), 100) : 20,
      Number.isFinite(s) ? Math.max(s, 0) : 0,
    ];
  }

  @Get('dashboard')
  @ApiQuery({
    name: 'period',
    required: false,
    description: 'today | week | month | year | all',
    example: 'month',
  })
  getDashboard(@Query('period') period = 'month') {
    return this.adminService.getDashboard(period);
  }

  @Get('users')
  @ApiQuery({ name: 'take', required: false, type: 'number', example: 20 })
  @ApiQuery({ name: 'skip', required: false, type: 'number', example: 0 })
  getUsers(@Query('take') take = 20, @Query('skip') skip = 0) {
    const [t, s] = AdminController.takeSkip(take, skip);
    return this.adminService.getUsers(t, s);
  }

  @Get('users/new')
  @ApiQuery({
    name: 'period',
    required: false,
    description: 'today | week | month | year | all',
    example: 'week',
  })
  @ApiQuery({ name: 'take', required: false, type: 'number', example: 20 })
  @ApiQuery({ name: 'skip', required: false, type: 'number', example: 0 })
  getNewUsers(
    @Query('period') period = 'week',
    @Query('take') take = 20,
    @Query('skip') skip = 0,
  ) {
    const [t, s] = AdminController.takeSkip(take, skip);
    return this.adminService.getNewUsers(period, t, s);
  }

  @Get('payments')
  @ApiQuery({ name: 'take', required: false, type: 'number', example: 20 })
  @ApiQuery({ name: 'skip', required: false, type: 'number', example: 0 })
  getPayments(@Query('take') take = 20, @Query('skip') skip = 0) {
    const [t, s] = AdminController.takeSkip(take, skip);
    return this.adminService.getPayments(t, s);
  }

  @Get('cancellations')
  @ApiQuery({ name: 'take', required: false, type: 'number', example: 20 })
  @ApiQuery({ name: 'skip', required: false, type: 'number', example: 0 })
  getCancellations(@Query('take') take = 20, @Query('skip') skip = 0) {
    const [t, s] = AdminController.takeSkip(take, skip);
    return this.adminService.getCancellations(t, s);
  }
}
