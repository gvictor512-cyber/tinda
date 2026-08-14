"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.GroupsService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const group_entity_1 = require("./entities/group.entity");
const group_member_entity_1 = require("./entities/group-member.entity");
const user_entity_1 = require("../users/entities/user.entity");
const profile_entity_1 = require("../profiles/entities/profile.entity");
const compatibility_service_1 = require("../compatibility/compatibility.service");
let GroupsService = class GroupsService {
    constructor(groupsRepository, groupMembersRepository, usersRepository, profilesRepository, compatibilityService) {
        this.groupsRepository = groupsRepository;
        this.groupMembersRepository = groupMembersRepository;
        this.usersRepository = usersRepository;
        this.profilesRepository = profilesRepository;
        this.compatibilityService = compatibilityService;
    }
    async createGroup(firebaseUid, createGroupDto) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const group = this.groupsRepository.create({
            name: createGroupDto.name,
            description: createGroupDto.description,
            creatorId: user.id,
            maxMembers: createGroupDto.maxMembers || 4,
            isActive: true,
        });
        const savedGroup = await this.groupsRepository.save(group);
        const member = this.groupMembersRepository.create({
            groupId: savedGroup.id,
            userId: user.id,
            role: 'creator',
        });
        await this.groupMembersRepository.save(member);
        await this.calculateGroupCompatibility(firebaseUid, savedGroup.id);
        return savedGroup;
    }
    async getUserGroups(firebaseUid) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const memberships = await this.groupMembersRepository.find({
            where: { userId: user.id },
            relations: ['group'],
        });
        const groups = await Promise.all(memberships.map(async (membership) => {
            const members = await this.groupMembersRepository.find({
                where: { groupId: membership.groupId },
                relations: ['user'],
            });
            const memberProfiles = await Promise.all(members.map(async (member) => {
                const profile = await this.profilesRepository.findOne({
                    where: { userId: member.userId },
                    relations: ['user'],
                });
                return {
                    ...member,
                    profile,
                };
            }));
            return {
                ...membership,
                members: memberProfiles,
                userRole: membership.role,
            };
        }));
        return groups;
    }
    async getGroup(firebaseUid, groupId) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const group = await this.groupsRepository.findOne({
            where: { id: groupId },
        });
        if (!group) {
            throw new common_1.NotFoundException('Group not found');
        }
        const membership = await this.groupMembersRepository.findOne({
            where: { groupId, userId: user.id },
        });
        if (!membership) {
            throw new common_1.BadRequestException('Access denied');
        }
        const members = await this.groupMembersRepository.find({
            where: { groupId },
            relations: ['user'],
        });
        const memberProfiles = await Promise.all(members.map(async (member) => {
            const profile = await this.profilesRepository.findOne({
                where: { userId: member.userId },
                relations: ['user'],
            });
            return {
                ...member,
                profile,
            };
        }));
        return {
            ...group,
            members: memberProfiles,
            userRole: membership.role,
        };
    }
    async updateGroup(firebaseUid, groupId, updateGroupDto) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const group = await this.groupsRepository.findOne({
            where: { id: groupId },
        });
        if (!group) {
            throw new common_1.NotFoundException('Group not found');
        }
        const membership = await this.groupMembersRepository.findOne({
            where: { groupId, userId: user.id },
        });
        if (!membership || (membership.role !== 'creator' && membership.role !== 'admin')) {
            throw new common_1.BadRequestException('Access denied');
        }
        Object.assign(group, updateGroupDto);
        const updatedGroup = await this.groupsRepository.save(group);
        return updatedGroup;
    }
    async deleteGroup(firebaseUid, groupId) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const group = await this.groupsRepository.findOne({
            where: { id: groupId },
        });
        if (!group) {
            throw new common_1.NotFoundException('Group not found');
        }
        if (group.creatorId !== user.id) {
            throw new common_1.BadRequestException('Only creator can delete the group');
        }
        await this.groupMembersRepository.delete({ groupId });
        await this.groupsRepository.remove(group);
        return { message: 'Group deleted successfully' };
    }
    async addMember(firebaseUid, groupId, addMemberDto) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const group = await this.groupsRepository.findOne({
            where: { id: groupId },
        });
        if (!group) {
            throw new common_1.NotFoundException('Group not found');
        }
        const membership = await this.groupMembersRepository.findOne({
            where: { groupId, userId: user.id },
        });
        if (!membership || (membership.role !== 'creator' && membership.role !== 'admin')) {
            throw new common_1.BadRequestException('Access denied');
        }
        const currentMembers = await this.groupMembersRepository.count({
            where: { groupId },
        });
        if (currentMembers >= group.maxMembers) {
            throw new common_1.BadRequestException('Group is full');
        }
        const targetUser = await this.usersRepository.findOne({
            where: { id: addMemberDto.userId },
        });
        if (!targetUser) {
            throw new common_1.NotFoundException('Target user not found');
        }
        const existingMember = await this.groupMembersRepository.findOne({
            where: { groupId, userId: addMemberDto.userId },
        });
        if (existingMember) {
            throw new common_1.BadRequestException('User is already a member');
        }
        const newMember = this.groupMembersRepository.create({
            groupId,
            userId: addMemberDto.userId,
            role: 'member',
        });
        await this.groupMembersRepository.save(newMember);
        await this.calculateGroupCompatibility(firebaseUid, groupId);
        return { message: 'Member added successfully' };
    }
    async removeMember(firebaseUid, groupId, memberId) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const group = await this.groupsRepository.findOne({
            where: { id: groupId },
        });
        if (!group) {
            throw new common_1.NotFoundException('Group not found');
        }
        const membership = await this.groupMembersRepository.findOne({
            where: { groupId, userId: user.id },
        });
        if (!membership) {
            throw new common_1.BadRequestException('Access denied');
        }
        const targetMember = await this.groupMembersRepository.findOne({
            where: { id: memberId },
        });
        if (!targetMember) {
            throw new common_1.NotFoundException('Member not found');
        }
        if (targetMember.role === 'creator') {
            throw new common_1.BadRequestException('Cannot remove creator');
        }
        if (targetMember.userId !== user.id && membership.role === 'member') {
            throw new common_1.BadRequestException('Access denied');
        }
        await this.groupMembersRepository.remove(targetMember);
        await this.calculateGroupCompatibility(firebaseUid, groupId);
        return { message: 'Member removed successfully' };
    }
    async leaveGroup(firebaseUid, groupId) {
        const user = await this.usersRepository.findOne({
            where: { firebaseUid },
        });
        if (!user) {
            throw new common_1.NotFoundException('User not found');
        }
        const group = await this.groupsRepository.findOne({
            where: { id: groupId },
        });
        if (!group) {
            throw new common_1.NotFoundException('Group not found');
        }
        if (group.creatorId === user.id) {
            throw new common_1.BadRequestException('Creator cannot leave. Delete the group instead.');
        }
        const membership = await this.groupMembersRepository.findOne({
            where: { groupId, userId: user.id },
        });
        if (!membership) {
            throw new common_1.BadRequestException('Not a member of this group');
        }
        await this.groupMembersRepository.remove(membership);
        await this.calculateGroupCompatibility(firebaseUid, groupId);
        return { message: 'Left group successfully' };
    }
    async calculateGroupCompatibility(firebaseUid, groupId) {
        const group = await this.groupsRepository.findOne({
            where: { id: groupId },
        });
        if (!group) {
            throw new common_1.NotFoundException('Group not found');
        }
        const members = await this.groupMembersRepository.find({
            where: { groupId },
        });
        if (members.length < 2) {
            group.compatibilityScore = 100;
            await this.groupsRepository.save(group);
            return { score: 100, explanation: 'Need more members to calculate compatibility' };
        }
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
                const compatibility = await this.compatibilityService.calculateCompatibility(user1.firebaseUid, user2.id);
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
        }
        else if (averageScore >= 70) {
            explanation = 'Buena compatibilidad grupal. Podríais convivir bien juntos.';
        }
        else if (averageScore >= 50) {
            explanation = 'Compatibilidad moderada. Algunas diferencias pero manejables.';
        }
        else {
            explanation = 'Baja compatibilidad grupal. Considerad revisar la dinámica del grupo.';
        }
        return {
            score: averageScore,
            explanation,
            memberCount: members.length,
        };
    }
};
exports.GroupsService = GroupsService;
exports.GroupsService = GroupsService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(group_entity_1.Group)),
    __param(1, (0, typeorm_1.InjectRepository)(group_member_entity_1.GroupMember)),
    __param(2, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(3, (0, typeorm_1.InjectRepository)(profile_entity_1.Profile)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        compatibility_service_1.CompatibilityService])
], GroupsService);
//# sourceMappingURL=groups.service.js.map