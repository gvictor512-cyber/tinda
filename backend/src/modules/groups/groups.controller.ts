import { Controller, Get, Post, Put, Delete, Body, UseGuards, Request, Param, ParseUUIDPipe, HttpCode, HttpStatus } from '@nestjs/common';
import { GroupsService } from './groups.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';
import { AddMemberDto } from './dto/add-member.dto';
import { FirebaseAuthGuard } from '../../common/guards/auth.guard';

@Controller('groups')
@UseGuards(FirebaseAuthGuard)
export class GroupsController {
  constructor(private readonly groupsService: GroupsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createGroup(@Request() req, @Body() createGroupDto: CreateGroupDto) {
    return this.groupsService.createGroup(req.user.uid, createGroupDto);
  }

  @Get()
  async getMyGroups(@Request() req) {
    return this.groupsService.getUserGroups(req.user.uid);
  }

  @Get(':id')
  async getGroup(@Request() req, @Param('id', ParseUUIDPipe) id: string) {
    return this.groupsService.getGroup(req.user.uid, id);
  }

  @Put(':id')
  async updateGroup(@Request() req, @Param('id', ParseUUIDPipe) id: string, @Body() updateGroupDto: UpdateGroupDto) {
    return this.groupsService.updateGroup(req.user.uid, id, updateGroupDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteGroup(@Request() req, @Param('id', ParseUUIDPipe) id: string) {
    return this.groupsService.deleteGroup(req.user.uid, id);
  }

  @Post(':id/members')
  async addMember(@Request() req, @Param('id', ParseUUIDPipe) id: string, @Body() addMemberDto: AddMemberDto) {
    return this.groupsService.addMember(req.user.uid, id, addMemberDto);
  }

  @Delete(':id/members/:memberId')
  @HttpCode(HttpStatus.NO_CONTENT)
  async removeMember(@Request() req, @Param('id', ParseUUIDPipe) id: string, @Param('memberId', ParseUUIDPipe) memberId: string) {
    return this.groupsService.removeMember(req.user.uid, id, memberId);
  }

  @Post(':id/leave')
  @HttpCode(HttpStatus.OK)
  async leaveGroup(@Request() req, @Param('id', ParseUUIDPipe) id: string) {
    return this.groupsService.leaveGroup(req.user.uid, id);
  }

  @Get(':id/compatibility')
  async getGroupCompatibility(@Request() req, @Param('id', ParseUUIDPipe) id: string) {
    return this.groupsService.calculateGroupCompatibility(req.user.uid, id);
  }
}
