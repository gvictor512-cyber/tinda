import { Controller, Get, Post, Put, Body, UseGuards, Request, HttpCode, HttpStatus } from '@nestjs/common';
import { FiltersService } from './filters.service';
import { UpdateFiltersDto } from './dto/update-filters.dto';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';

@Controller('filters')
@UseGuards(FirebaseAuthGuard)
export class FiltersController {
  constructor(private readonly filtersService: FiltersService) {}

  @Get()
  async getMyFilters(@Request() req) {
    return this.filtersService.getUserFilters(req.user.uid);
  }

  @Put()
  async updateFilters(@Request() req, @Body() updateFiltersDto: UpdateFiltersDto) {
    return this.filtersService.updateFilters(req.user.uid, updateFiltersDto);
  }

  @Post('reset')
  @HttpCode(HttpStatus.OK)
  async resetFilters(@Request() req) {
    return this.filtersService.resetFilters(req.user.uid);
  }
}
