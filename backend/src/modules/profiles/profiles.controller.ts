import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards, Request, ParseUUIDPipe, HttpCode, HttpStatus } from '@nestjs/common';
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
