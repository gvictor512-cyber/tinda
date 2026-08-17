export declare class User {
    id: string;
    firebaseUid: string;
    email: string;
    displayName: string;
    phone: string;
    birthDate: Date;
    consent: Record<string, unknown>;
    isActive: boolean;
    isPremium: boolean;
    premiumExpiresAt: Date;
    isVerified: boolean;
    deletedAt: Date;
    acceptedTermsAt: Date;
    acceptedPrivacyAt: Date;
    acceptedCookiesAt: Date;
    createdAt: Date;
    updatedAt: Date;
}
