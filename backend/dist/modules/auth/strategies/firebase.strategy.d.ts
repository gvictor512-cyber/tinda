import { Strategy } from 'passport-custom';
declare const FirebaseStrategy_base: new (...args: any[]) => Strategy;
export declare class FirebaseStrategy extends FirebaseStrategy_base {
    constructor();
    validate(req: any): Promise<{
        uid: string;
        email: string;
        emailVerified: boolean;
    }>;
    private extractTokenFromHeader;
}
export {};
