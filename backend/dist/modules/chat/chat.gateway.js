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
exports.ChatGateway = void 0;
const websockets_1 = require("@nestjs/websockets");
const socket_io_1 = require("socket.io");
const chat_service_1 = require("./chat.service");
let ChatGateway = class ChatGateway {
    constructor(chatService) {
        this.chatService = chatService;
    }
    async handleConnection(client) {
        try {
            const userId = client.handshake.auth.userId;
            if (userId) {
                client.join(`user_${userId}`);
                console.log(`User ${userId} connected`);
            }
        }
        catch (error) {
            client.disconnect();
        }
    }
    handleDisconnect(client) {
        console.log(`Client disconnected: ${client.id}`);
    }
    async handleJoinMatch(client, data) {
        const userId = client.handshake.auth.userId;
        const match = await this.chatService.verifyMatchAccess(userId, data.matchId);
        if (match) {
            client.join(`match_${data.matchId}`);
            client.emit('joinedMatch', { matchId: data.matchId });
        }
        else {
            client.emit('error', { message: 'Access denied' });
        }
    }
    async handleLeaveMatch(client, data) {
        client.leave(`match_${data.matchId}`);
        client.emit('leftMatch', { matchId: data.matchId });
    }
    async handleSendMessage(client, data) {
        const userId = client.handshake.auth.userId;
        try {
            const message = await this.chatService.createMessage({
                matchId: data.matchId,
                senderId: userId,
                messageType: data.messageType,
                content: data.content,
                mediaUrl: data.mediaUrl,
                locationData: data.locationData,
            });
            this.server.to(`match_${data.matchId}`).emit('newMessage', message);
            const match = await this.chatService.getMatch(data.matchId);
            const receiverId = match.user1Id === userId ? match.user2Id : match.user1Id;
            const receiverSockets = await this.server.in(`user_${receiverId}`).allSockets();
            if (receiverSockets.size === 0) {
                await this.chatService.sendNewMessageNotification(receiverId, userId, data.matchId);
            }
            return message;
        }
        catch (error) {
            client.emit('error', { message: 'Failed to send message' });
        }
    }
    async handleMarkAsRead(client, data) {
        const userId = client.handshake.auth.userId;
        await this.chatService.markMessagesAsRead(data.matchId, userId);
        const match = await this.chatService.getMatch(data.matchId);
        const otherUserId = match.user1Id === userId ? match.user2Id : match.user1Id;
        this.server.to(`match_${data.matchId}`).emit('messagesRead', {
            matchId: data.matchId,
            userId,
        });
    }
    async handleTyping(client, data) {
        const userId = client.handshake.auth.userId;
        client.to(`match_${data.matchId}`).emit('userTyping', {
            matchId: data.matchId,
            userId,
            isTyping: data.isTyping,
        });
    }
};
exports.ChatGateway = ChatGateway;
__decorate([
    (0, websockets_1.WebSocketServer)(),
    __metadata("design:type", socket_io_1.Server)
], ChatGateway.prototype, "server", void 0);
__decorate([
    (0, websockets_1.SubscribeMessage)('joinMatch'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, Object]),
    __metadata("design:returntype", Promise)
], ChatGateway.prototype, "handleJoinMatch", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('leaveMatch'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, Object]),
    __metadata("design:returntype", Promise)
], ChatGateway.prototype, "handleLeaveMatch", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('sendMessage'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, Object]),
    __metadata("design:returntype", Promise)
], ChatGateway.prototype, "handleSendMessage", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('markAsRead'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, Object]),
    __metadata("design:returntype", Promise)
], ChatGateway.prototype, "handleMarkAsRead", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('typing'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, Object]),
    __metadata("design:returntype", Promise)
], ChatGateway.prototype, "handleTyping", null);
exports.ChatGateway = ChatGateway = __decorate([
    (0, websockets_1.WebSocketGateway)({
        cors: {
            origin: '*',
        },
    }),
    __metadata("design:paramtypes", [chat_service_1.ChatService])
], ChatGateway);
//# sourceMappingURL=chat.gateway.js.map