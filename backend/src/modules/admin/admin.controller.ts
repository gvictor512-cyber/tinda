import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';

@ApiTags('admin')
@Controller('admin')
@UseGuards(FirebaseAuthGuard)
@ApiBearerAuth()
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard')
  @ApiQuery({ name: 'period', required: false, description: 'today | week | month | year | all', example: 'month' })
  getDashboard(@Query('period') period = 'month') {
    return this.adminService.getDashboard(period);
  }

  @Get('users')
  @ApiQuery({ name: 'take', required: false, type: 'number', example: 20 })
  @ApiQuery({ name: 'skip', required: false, type: 'number', example: 0 })
  getUsers(
    @Query('take') take = 20,
    @Query('skip') skip = 0,
  ) {
    return this.adminService.getUsers(Number(take), Number(skip));
  }

  @Get('users/new')
  @ApiQuery({ name: 'period', required: false, description: 'today | week | month | year | all', example: 'week' })
  @ApiQuery({ name: 'take', required: false, type: 'number', example: 20 })
  @ApiQuery({ name: 'skip', required: false, type: 'number', example: 0 })
  getNewUsers(
    @Query('period') period = 'week',
    @Query('take') take = 20,
    @Query('skip') skip = 0,
  ) {
    return this.adminService.getNewUsers(period, Number(take), Number(skip));
  }

  @Get('payments')
  @ApiQuery({ name: 'take', required: false, type: 'number', example: 20 })
  @ApiQuery({ name: 'skip', required: false, type: 'number', example: 0 })
  getPayments(
    @Query('take') take = 20,
    @Query('skip') skip = 0,
  ) {
    return this.adminService.getPayments(Number(take), Number(skip));
  }

  @Get('cancellations')
  @ApiQuery({ name: 'take', required: false, type: 'number', example: 20 })
  @ApiQuery({ name: 'skip', required: false, type: 'number', example: 0 })
  getCancellations(
    @Query('take') take = 20,
    @Query('skip') skip = 0,
  ) {
    return this.adminService.getCancellations(Number(take), Number(skip));
  }
}
