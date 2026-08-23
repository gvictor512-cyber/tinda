import { Injectable, Logger } from '@nestjs/common';

interface VeriffSession {
  id: string;
  status: string;
  url?: string;
}

@Injectable()
export class VeriffService {
  private readonly apiUrl = 'https://stationapi.veriff.com/v1';
  private readonly logger = new Logger(VeriffService.name);

  async createSession(userId: string, email: string): Promise<VeriffSession> {
    const apiKey = process.env.VERIFF_API_KEY;
    const clientId = process.env.VERIFF_CLIENT_ID;

    if (!apiKey || !clientId) {
      this.logger.warn('VERIFF_API_KEY or VERIFF_CLIENT_ID not set');
      return { id: 'veriff-mock-' + userId, status: 'approved' };
    }

    const response = await fetch(`${this.apiUrl}/sessions`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'X-AUTH-CLIENT': clientId,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        verification: {
          person: {
            firstName: 'User',
            lastName: userId,
            email,
          },
          timestamp: new Date().toISOString(),
        },
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Veriff session creation failed: ${text}`);
    }

    const data = await response.json();
    return { id: data.verification.id, status: data.verification.status, url: data.verification.url };
  }

  async getSession(sessionId: string): Promise<VeriffSession> {
    const apiKey = process.env.VERIFF_API_KEY;
    const clientId = process.env.VERIFF_CLIENT_ID;

    if (!apiKey || !clientId) {
      this.logger.warn('VERIFF_API_KEY or VERIFF_CLIENT_ID not set');
      return { id: sessionId, status: 'approved' };
    }

    const response = await fetch(`${this.apiUrl}/sessions/${sessionId}`, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'X-AUTH-CLIENT': clientId,
      },
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Veriff session status failed: ${text}`);
    }

    const data = await response.json();
    return { id: data.verification.id, status: data.verification.status, url: data.verification.url };
  }
}
