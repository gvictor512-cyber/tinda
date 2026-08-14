import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Group } from './entities/group.entity';
import { GroupMember } from './entities/group-member.entity';
import { User } from '../users/entities/user.entity';
import { Profile } from '../profiles/entities/profile.entity';
import { CompatibilityService } from '../compatibility/compatibility.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';
import { AddMemberDto } from './dto/add-member.dto';

@Injectable()
export class GroupsService {
  constructor(
    @InjectRepository(Group)
    private groupsRepository: Repository<Group>,
    @InjectRepository(GroupMember)
    private groupMembersRepository: Repository<GroupMember>,
    @InjectRepository(User)
    private usersRepository: Repository<User>,
    @InjectRepository(Profile)
    private profilesRepository: Repository<Profile>,
    private compatibilityService: CompatibilityService,
  ) {}

  async createGroup(firebaseUid: string, createGroupDto: CreateGroupDto) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const group = this.groupsRepository.create({
      name: createGroupDto.name,
      description: createGroupDto.description,
      creatorId: user.id,
      maxMembers: createGroupDto.maxMembers || 4,
      isActive: true,
    });

    const savedGroup = await this.groupsRepository.save(group);

    // Add creator as first member
    const member = this.groupMembersRepository.create({
      groupId: savedGroup.id,
      userId: user.id,
      role: 'creator',
    });

    await this.groupMembersRepository.save(member);

    // Calculate initial compatibility
    await this.calculateGroupCompatibility(firebaseUid, savedGroup.id);

    return savedGroup;
  }

  async getUserGroups(firebaseUid: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const memberships = await this.groupMembersRepository.find({
      where: { userId: user.id },
      relations: ['group'],
    });

    const groups = await Promise.all(
      memberships.map(async (membership) => {
        const members = await this.groupMembersRepository.find({
          where: { groupId: membership.groupId },
          relations: ['user'],
        });

        const memberProfiles = await Promise.all(
          members.map(async (member) => {
            const profile = await this.profilesRepository.findOne({
              where: { userId: member.userId },
              relations: ['user'],
            });
            return {
              ...member,
              profile,
            };
          }),
        );

        return {
          ...membership,
          members: memberProfiles,
          userRole: membership.role,
        };
      }),
    );

    return groups;
  }

  async getGroup(firebaseUid: string, groupId: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const group = await this.groupsRepository.findOne({
      where: { id: groupId },
    });

    if (!group) {
      throw new NotFoundException('Group not found');
    }

    // Verify user is a member
    const membership = await this.groupMembersRepository.findOne({
      where: { groupId, userId: user.id },
    });

    if (!membership) {
      throw new BadRequestException('Access denied');
    }

    const members = await this.groupMembersRepository.find({
      where: { groupId },
      relations: ['user'],
    });

    const memberProfiles = await Promise.all(
      members.map(async (member) => {
        const profile = await this.profilesRepository.findOne({
          where: { userId: member.userId },
          relations: ['user'],
        });
        return {
          ...member,
          profile,
        };
      }),
    );

    return {
      ...group,
      members: memberProfiles,
      userRole: membership.role,
    };
  }

  async updateGroup(firebaseUid: string, groupId: string, updateGroupDto: UpdateGroupDto) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const group = await this.groupsRepository.findOne({
      where: { id: groupId },
    });

    if (!group) {
      throw new NotFoundException('Group not found');
    }

    // Verify user is creator or admin
    const membership = await this.groupMembersRepository.findOne({
      where: { groupId, userId: user.id },
    });

    if (!membership || (membership.role !== 'creator' && membership.role !== 'admin')) {
      throw new BadRequestException('Access denied');
    }

    Object.assign(group, updateGroupDto);
    const updatedGroup = await this.groupsRepository.save(group);

    return updatedGroup;
  }

  async deleteGroup(firebaseUid: string, groupId: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const group = await this.groupsRepository.findOne({
      where: { id: groupId },
    });

    if (!group) {
      throw new NotFoundException('Group not found');
    }

    // Only creator can delete
    if (group.creatorId !== user.id) {
      throw new BadRequestException('Only creator can delete the group');
    }

    await this.groupMembersRepository.delete({ groupId });
    await this.groupsRepository.remove(group);

    return { message: 'Group deleted successfully' };
  }

  async addMember(firebaseUid: string, groupId: string, addMemberDto: AddMemberDto) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const group = await this.groupsRepository.findOne({
      where: { id: groupId },
    });

    if (!group) {
      throw new NotFoundException('Group not found');
    }

    // Verify user is creator or admin
    const membership = await this.groupMembersRepository.findOne({
      where: { groupId, userId: user.id },
    });

    if (!membership || (membership.role !== 'creator' && membership.role !== 'admin')) {
      throw new BadRequestException('Access denied');
    }

    // Check if group is full
    const currentMembers = await this.groupMembersRepository.count({
      where: { groupId },
    });

    if (currentMembers >= group.maxMembers) {
      throw new BadRequestException('Group is full');
    }

    // Check if user already exists
    const targetUser = await this.usersRepository.findOne({
      where: { id: addMemberDto.userId },
    });

    if (!targetUser) {
      throw new NotFoundException('Target user not found');
    }

    const existingMember = await this.groupMembersRepository.findOne({
      where: { groupId, userId: addMemberDto.userId },
    });

    if (existingMember) {
      throw new BadRequestException('User is already a member');
    }

    const newMember = this.groupMembersRepository.create({
      groupId,
      userId: addMemberDto.userId,
      role: 'member',
    });

    await this.groupMembersRepository.save(newMember);

    // Recalculate group compatibility
    await this.calculateGroupCompatibility(firebaseUid, groupId);

    return { message: 'Member added successfully' };
  }

  async removeMember(firebaseUid: string, groupId: string, memberId: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const group = await this.groupsRepository.findOne({
      where: { id: groupId },
    });

    if (!group) {
      throw new NotFoundException('Group not found');
    }

    // Verify user is creator or admin, or removing themselves
    const membership = await this.groupMembersRepository.findOne({
      where: { groupId, userId: user.id },
    });

    if (!membership) {
      throw new BadRequestException('Access denied');
    }

    const targetMember = await this.groupMembersRepository.findOne({
      where: { id: memberId },
    });

    if (!targetMember) {
      throw new NotFoundException('Member not found');
    }

    // Can't remove creator
    if (targetMember.role === 'creator') {
      throw new BadRequestException('Cannot remove creator');
    }

    // Only creator/admin can remove others, users can remove themselves
    if (targetMember.userId !== user.id && membership.role === 'member') {
      throw new BadRequestException('Access denied');
    }

    await this.groupMembersRepository.remove(targetMember);

    // Recalculate group compatibility
    await this.calculateGroupCompatibility(firebaseUid, groupId);

    return { message: 'Member removed successfully' };
  }

  async leaveGroup(firebaseUid: string, groupId: string) {
    const user = await this.usersRepository.findOne({
      where: { firebaseUid },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const group = await this.groupsRepository.findOne({
      where: { id: groupId },
    });

    if (!group) {
      throw new NotFoundException('Group not found');
    }

    // Creator cannot leave, must delete group instead
    if (group.creatorId === user.id) {
      throw new BadRequestException('Creator cannot leave. Delete the group instead.');
    }

    const membership = await this.groupMembersRepository.findOne({
      where: { groupId, userId: user.id },
    });

    if (!membership) {
      throw new BadRequestException('Not a member of this group');
    }

    await this.groupMembersRepository.remove(membership);

    // Recalculate group compatibility
    await this.calculateGroupCompatibility(firebaseUid, groupId);

    return { message: 'Left group successfully' };
  }

  async calculateGroupCompatibility(firebaseUid: string, groupId: string) {
    const group = await this.groupsRepository.findOne({
      where: { id: groupId },
    });

    if (!group) {
      throw new NotFoundException('Group not found');
    }

    const members = await this.groupMembersRepository.find({
      where: { groupId },
    });

    if (members.length < 2) {
      group.compatibilityScore = 100;
      await this.groupsRepository.save(group);
      return { score: 100, explanation: 'Need more members to calculate compatibility' };
    }

    // Calculate pairwise compatibility between all members
    let totalScore = 0;
    let pairCount = 0;

    for (let i = 0; i < members.length; i++) {
      for (let j = i + 1; j < members.length; j++) {
        const user1 = await this.usersRepository.findOne({
          where: { id: members[i].userId },
        });
        const user2 = await this.usersRepository.findOne({
          where: { id: members[j].userId },
        });

        const compatibility = await this.compatibilityService.calculateCompatibility(
          user1.firebaseUid,
          user2.id,
        );

        totalScore += compatibility.score;
        pairCount++;
      }
    }

    const averageScore = pairCount > 0 ? Math.round(totalScore / pairCount) : 0;

    group.compatibilityScore = averageScore;
    await this.groupsRepository.save(group);

    let explanation = '';
    if (averageScore >= 85) {
      explanation = 'Excelente compatibilidad grupal. ¡Formáis un gran equipo!';
    } else if (averageScore >= 70) {
      explanation = 'Buena compatibilidad grupal. Podríais convivir bien juntos.';
    } else if (averageScore >= 50) {
      explanation = 'Compatibilidad moderada. Algunas diferencias pero manejables.';
    } else {
      explanation = 'Baja compatibilidad grupal. Considerad revisar la dinámica del grupo.';
    }

    return {
      score: averageScore,
      explanation,
      memberCount: members.length,
    };
  }
}
