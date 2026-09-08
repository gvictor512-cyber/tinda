import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards, Request, ParseUUIDPipe, ParseIntPipe, DefaultValuePipe, HttpCode, HttpStatus } from '@nestjs/common';
import { ProfilesService } from './profiles.service';
import { CreateProfileDto } from './dto/create-profile.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';

@Controller('profiles')
@UseGuards(FirebaseAuthGuard)
export class ProfilesController {
  constructor(private readonly profilesService: ProfilesService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Request() req, @Body() createProfileDto: CreateProfileDto) {
    return this.profilesService.create(req.user.uid, createProfileDto);
  }

  @Get()
  async findMyProfile(@Request() req) {
    return this.profilesService.findByUserId(req.user.uid);
  }

  @Get('search')
  async search(
    @Query('city') city?: string,
    @Query('ageMin') ageMin?: string,
    @Query('ageMax') ageMax?: string,
    @Query('budgetMin') budgetMin?: string,
    @Query('budgetMax') budgetMax?: string,
    @Query('gender') gender?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
  ) {
    const filters: any = {};
    if (city) filters.city = city;
    if (ageMin) filters.ageMin = parseInt(ageMin, 10);
    if (ageMax) filters.ageMax = parseInt(ageMax, 10);
    if (budgetMin) filters.budgetMin = parseInt(budgetMin, 10);
    if (budgetMax) filters.budgetMax = parseInt(budgetMax, 10);
    if (gender) filters.gender = gender;

    return this.profilesService.searchProfiles(filters, page, limit);
  }

  @Get('city/:city')
  async findByCity(
    @Param('city') city: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number = 1,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number = 20,
  ) {
    return this.profilesService.findProfilesByCity(city, page, limit);
  }

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.profilesService.findOne(id);
  }

  @Put()
  async update(@Request() req, @Body() updateProfileDto: UpdateProfileDto) {
    return this.profilesService.update(req.user.uid, updateProfileDto);
  }

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  async delete(@Request() req) {
    return this.profilesService.delete(req.user.uid);
  }

  @Post('photos')
  async addPhoto(@Request() req, @Body('photoUrl') photoUrl: string) {
    return this.profilesService.addPhoto(req.user.uid, photoUrl);
  }

  @Delete('photos/:index')
  async removePhoto(@Request() req, @Param('index') index: string) {
    return this.profilesService.removePhoto(req.user.uid, parseInt(index));
  }
}
