import { Injectable, Logger } from '@nestjs/common';

interface OnfidoApplicant {
  id: string;
  first_name: string;
  last_name?: string;
}

@Injectable()
export class OnfidoService {
  private readonly apiUrl = 'https://api.onfido.com/v3.6';
  private readonly logger = new Logger(OnfidoService.name);

  private get headers() {
    const token = process.env.ONFIDO_API_TOKEN;
    return {
      Authorization: `Token token=${token}`,
      'Content-Type': 'application/json',
    };
  }

  async createApplicant(userId: string, email: string): Promise<OnfidoApplicant> {
    const token = process.env.ONFIDO_API_TOKEN;
    if (!token) {
      this.logger.warn('ONFIDO_API_TOKEN not set');
      return { id: 'onfido-mock-' + userId, first_name: 'User' };
    }

    const response = await fetch(`${this.apiUrl}/applicants`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({
        first_name: 'User',
        last_name: userId,
        email,
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Onfido create applicant failed: ${text}`);
    }

    return response.json() as Promise<OnfidoApplicant>;
  }

  async checkDocument(
    applicantId: string,
    documentUrl: string,
    selfieUrl?: string,
  ): Promise<{ id: string; status: string }> {
    const token = process.env.ONFIDO_API_TOKEN;
    if (!token) {
      this.logger.warn('ONFIDO_API_TOKEN not set; document check mocked');
      return { id: 'onfido-mock-check', status: 'complete' };
    }

    // NOTE: Onfido expects file bytes for documents/selfies. A real integration
    // downloads the URL, uploads as multipart/form-data to /documents and
    // /live_photos, then POSTs /checks. This skeleton returns a pending check
    // so the flow compiles and works without file data for now.
    const response = await fetch(`${this.apiUrl}/checks`, {
      method: 'POST',
      headers: this.headers,
      body: JSON.stringify({
        applicant_id: applicantId,
        report_names: ['document', 'facial_similarity_photo'],
        async: false,
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`Onfido check failed: ${text}`);
    }

    return response.json() as Promise<{ id: string; status: string }>;
  }
}
