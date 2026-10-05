import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-custom';
import { admin } from '../config/firebase.config';

@Injectable()
export class FirebaseStrategy extends PassportStrategy(Strategy, 'firebase') {
  async validate(req: any) {
    const idToken = req.headers?.authorization?.replace('Bearer ', '');
    
    if (!idToken) {
      throw new UnauthorizedException('No token provided');
    }

    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);

      // Populate the role so RolesGuard works. An account is admin when the
      // Firestore users doc says role='admin' OR an admins/{uid} doc exists
      // (both are manageable from the Firebase console).
      let role = decodedToken.role as string | undefined;
      if (!role) {
        try {
          const db = admin.firestore();
          const adminDoc = await db.collection('admins').doc(decodedToken.uid).get();
          if (adminDoc.exists) {
            role = 'admin';
          } else {
            const userDoc = await db.collection('users').doc(decodedToken.uid).get();
            role = (userDoc.data()?.role as string | undefined) ?? 'user';
          }
        } catch {
          role = 'user';
        }
      }

      return {
        uid: decodedToken.uid,
        email: decodedToken.email,
        role,
      };
    } catch (error) {
      throw new UnauthorizedException('Invalid token');
    }
  }
}
