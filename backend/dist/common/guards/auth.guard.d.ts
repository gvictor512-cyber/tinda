declare const FirebaseAuthGuard_base: import("@nestjs/passport").Type<import("@nestjs/passport").IAuthGuard>;
export declare class FirebaseAuthGuard extends FirebaseAuthGuard_base {
    handleRequest(err: any, user: any, info: any): any;
}
export {};
