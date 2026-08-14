import { Repository } from 'typeorm';
import { Group } from './entities/group.entity';
import { GroupMember } from './entities/group-member.entity';
import { User } from '../users/entities/user.entity';
import { Profile } from '../profiles/entities/profile.entity';
import { CompatibilityService } from '../compatibility/compatibility.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';
import { AddMemberDto } from './dto/add-member.dto';
export declare class GroupsService {
    private groupsRepository;
    private groupMembersRepository;
    private usersRepository;
    private profilesRepository;
    private compatibilityService;
    constructor(groupsRepository: Repository<Group>, groupMembersRepository: Repository<GroupMember>, usersRepository: Repository<User>, profilesRepository: Repository<Profile>, compatibilityService: CompatibilityService);
    createGroup(firebaseUid: string, createGroupDto: CreateGroupDto): Promise<Group>;
    getUserGroups(firebaseUid: string): Promise<{
        members: {
            profile: Profile;
            id: string;
            groupId: string;
            userId: string;
            role: string;
            joinedAt: Date;
        }[];
        userRole: string;
        id: string;
        groupId: string;
        userId: string;
        role: string;
        joinedAt: Date;
    }[]>;
    getGroup(firebaseUid: string, groupId: string): Promise<{
        members: {
            profile: Profile;
            id: string;
            groupId: string;
            userId: string;
            role: string;
            joinedAt: Date;
        }[];
        userRole: string;
        id: string;
        name: string;
        description: string;
        creatorId: string;
        maxMembers: number;
        compatibilityScore: number;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
    }>;
    updateGroup(firebaseUid: string, groupId: string, updateGroupDto: UpdateGroupDto): Promise<Group>;
    deleteGroup(firebaseUid: string, groupId: string): Promise<{
        message: string;
    }>;
    addMember(firebaseUid: string, groupId: string, addMemberDto: AddMemberDto): Promise<{
        message: string;
    }>;
    removeMember(firebaseUid: string, groupId: string, memberId: string): Promise<{
        message: string;
    }>;
    leaveGroup(firebaseUid: string, groupId: string): Promise<{
        message: string;
    }>;
    calculateGroupCompatibility(firebaseUid: string, groupId: string): Promise<{
        score: number;
        explanation: string;
        memberCount?: undefined;
    } | {
        score: number;
        explanation: string;
        memberCount: number;
    }>;
}
