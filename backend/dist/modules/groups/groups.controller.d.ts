import { GroupsService } from './groups.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { UpdateGroupDto } from './dto/update-group.dto';
import { AddMemberDto } from './dto/add-member.dto';
export declare class GroupsController {
    private readonly groupsService;
    constructor(groupsService: GroupsService);
    createGroup(req: any, createGroupDto: CreateGroupDto): Promise<import("./entities/group.entity").Group>;
    getMyGroups(req: any): Promise<{
        members: {
            profile: import("../profiles/entities/profile.entity").Profile;
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
    getGroup(req: any, id: string): Promise<{
        members: {
            profile: import("../profiles/entities/profile.entity").Profile;
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
    updateGroup(req: any, id: string, updateGroupDto: UpdateGroupDto): Promise<import("./entities/group.entity").Group>;
    deleteGroup(req: any, id: string): Promise<{
        message: string;
    }>;
    addMember(req: any, id: string, addMemberDto: AddMemberDto): Promise<{
        message: string;
    }>;
    removeMember(req: any, id: string, memberId: string): Promise<{
        message: string;
    }>;
    leaveGroup(req: any, id: string): Promise<{
        message: string;
    }>;
    getGroupCompatibility(req: any, id: string): Promise<{
        score: number;
        explanation: string;
        memberCount?: undefined;
    } | {
        score: number;
        explanation: string;
        memberCount: number;
    }>;
}
