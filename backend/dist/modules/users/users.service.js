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
exports.UsersService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const user_entity_1 = require("./entities/user.entity");
const consent_log_entity_1 = require("./entities/consent-log.entity");
const data_request_entity_1 = require("./entities/data-request.entity");
let UsersService = class UsersService {
    constructor(usersRepository, consentLogRepository, dataRequestRepository) {
        this.usersRepository = usersRepository;
        this.consentLogRepository = consentLogRepository;
        this.dataRequestRepository = dataRequestRepository;
    }
    async findByFirebaseUid(firebaseUid) {
        return this.usersRepository.findOne({ where: { firebaseUid } });
    }
    async create(firebaseUid, email) {
        const user = this.usersRepository.create({
            firebaseUid,
            email,
        });
        return this.usersRepository.save(user);
    }
    async logConsent(firebaseUid, consentType, accepted, metadata) {
        const user = await this.findByFirebaseUid(firebaseUid);
        if (!user)
            throw new common_1.NotFoundException('User not found');
        const fieldMap = {
            terms: 'acceptedTermsAt',
            privacy: 'acceptedPrivacyAt',
            cookies: 'acceptedCookiesAt',
        };
        const field = fieldMap[consentType];
        if (field) {
            user[field] = accepted ? new Date() : null;
        }
        const consent = (user.consent || {});
        consent[consentType] = { accepted, at: new Date().toISOString() };
        user.consent = consent;
        await this.usersRepository.save(user);
        const log = this.consentLogRepository.create({
            userId: user.id,
            firebaseUid,
            consentType,
            accepted,
            version: metadata?.version || '1.0',
            ipAddress: metadata?.ip,
            userAgent: metadata?.userAgent,
        });
        return { user: await this.findByFirebaseUid(firebaseUid), log: await this.consentLogRepository.save(log) };
    }
    async exportData(firebaseUid) {
        const user = await this.findByFirebaseUid(firebaseUid);
        if (!user)
            throw new common_1.NotFoundException('User not found');
        const consents = await this.consentLogRepository.find({
            where: { firebaseUid },
            order: { createdAt: 'DESC' },
        });
        await this.dataRequestRepository.save(this.dataRequestRepository.create({
            userId: user.id,
            firebaseUid,
            requestType: 'export',
            status: 'completed',
            payload: { userEmail: user.email },
            completedAt: new Date(),
        }));
        return {
            user: {
                id: user.id,
                firebaseUid: user.firebaseUid,
                email: user.email,
                displayName: user.displayName,
                phone: user.phone,
                birthDate: user.birthDate,
                isActive: user.isActive,
                isPremium: user.isPremium,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt,
                consent: user.consent,
            },
            consents: consents.map((c) => ({
                consentType: c.consentType,
                accepted: c.accepted,
                version: c.version,
                createdAt: c.createdAt,
            })),
        };
    }
    async deleteUser(firebaseUid) {
        const user = await this.findByFirebaseUid(firebaseUid);
        if (!user)
            throw new common_1.NotFoundException('User not found');
        user.isActive = false;
        user.deletedAt = new Date();
        await this.usersRepository.save(user);
        const request = this.dataRequestRepository.create({
            userId: user.id,
            firebaseUid,
            requestType: 'deletion',
            status: 'completed',
            completedAt: new Date(),
        });
        return this.dataRequestRepository.save(request);
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(1, (0, typeorm_1.InjectRepository)(consent_log_entity_1.ConsentLog)),
    __param(2, (0, typeorm_1.InjectRepository)(data_request_entity_1.DataRequest)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository])
], UsersService);
//# sourceMappingURL=users.service.js.map