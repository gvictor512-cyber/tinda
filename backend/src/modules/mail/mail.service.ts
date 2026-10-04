import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface PurchaseReceiptData {
  to: string;
  customerName?: string;
  invoiceNumber: string;
  purchaseDate: Date;
  productName: string;
  productDescription?: string;
  amountCents: number;
  currency: string;
  platform: string;
  transactionId: string;
}

const APP_NAME = 'RoomMate Match';
const SELLER_NAME = 'Victor Garcia Caballero';
const SELLER_LOCATION = 'Barcelona, España';
const SUPPORT_EMAIL = 'support@roommatematchapp.com';
const VAT_RATE = 0.21; // IVA aplicable en España para servicios digitales (incluido en el precio)

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private readonly apiKey?: string;
  private readonly from: string;
  private readonly enabled: boolean;

  constructor(private readonly configService: ConfigService) {
    this.apiKey = this.configService.get<string>('RESEND_API_KEY');
    this.from =
      this.configService.get<string>('MAIL_FROM') ||
      `${APP_NAME} <facturas@roommatematchapp.com>`;
    this.enabled = Boolean(this.apiKey) && !this.apiKey.includes('YOUR_RESEND_API_KEY');
    if (!this.enabled) {
      this.logger.warn(
        'RESEND_API_KEY no configurada: los emails de factura estan deshabilitados.',
      );
    }
  }

  /**
   * Envia la factura de una compra al email del usuario.
   * Devuelve true si el proveedor acepto el envio, false en caso contrario.
   * Nunca lanza excepciones: el envio de email es best-effort.
   */
  async sendPurchaseReceipt(data: PurchaseReceiptData): Promise<boolean> {
    if (!this.enabled) {
      this.logger.log(
        `Factura ${data.invoiceNumber} no enviada (servicio de email deshabilitado)`,
      );
      return false;
    }

    return this.send({
      to: data.to,
      subject: `Tu factura de ${APP_NAME} - ${data.invoiceNumber}`,
      html: this.buildReceiptHtml(data),
      text: this.buildReceiptText(data),
    });
  }

  /** Envio via API de Resend (HTTP, no requiere puertos SMTP). */
  private async send(params: {
    to: string;
    subject: string;
    html: string;
    text: string;
  }): Promise<boolean> {
    try {
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: this.from,
          to: [params.to],
          subject: params.subject,
          html: params.html,
          text: params.text,
        }),
        signal: AbortSignal.timeout(10_000),
      });

      if (!response.ok) {
        const body = await response.text();
        this.logger.error(`Resend respondio ${response.status}: ${body}`);
        return false;
      }
      return true;
    } catch (error) {
      this.logger.error(
        `Error enviando email: ${error instanceof Error ? error.message : String(error)}`,
      );
      return false;
    }
  }

  private formatAmount(cents: number, currency: string): string {
    try {
      return new Intl.NumberFormat('es-ES', { style: 'currency', currency }).format(
        cents / 100,
      );
    } catch {
      return `${(cents / 100).toFixed(2)} ${currency}`;
    }
  }

  private formatDate(date: Date): string {
    return new Intl.DateTimeFormat('es-ES', {
      day: '2-digit',
      month: 'long',
      year: 'numeric',
    }).format(date);
  }

  private platformLabel(platform: string): string {
    switch (platform) {
      case 'ios':
        return 'Apple App Store';
      case 'android':
        return 'Google Play Store';
      case 'web':
        return 'Stripe (web)';
      default:
        return platform || 'Tienda de aplicaciones';
    }
  }

  private escapeHtml(value: string): string {
    return value
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  private buildReceiptHtml(data: PurchaseReceiptData): string {
    const total = this.formatAmount(data.amountCents, data.currency);
    const isEur = data.currency.toUpperCase() === 'EUR';
    const baseCents = Math.round(data.amountCents / (1 + VAT_RATE));
    const vatCents = data.amountCents - baseCents;

    const taxRows = isEur
      ? `
            <tr>
              <td style="padding:8px 0;color:#666;">Base imponible</td>
              <td style="padding:8px 0;text-align:right;">${this.formatAmount(baseCents, data.currency)}</td>
            </tr>
            <tr>
              <td style="padding:8px 0;color:#666;">IVA (21%) incluido</td>
              <td style="padding:8px 0;text-align:right;">${this.formatAmount(vatCents, data.currency)}</td>
            </tr>`
      : `
            <tr>
              <td style="padding:8px 0;color:#666;">Impuestos</td>
              <td style="padding:8px 0;text-align:right;">Incluidos</td>
            </tr>`;

    return `<!DOCTYPE html>
<html lang="es">
<head><meta charset="utf-8"><title>Factura ${data.invoiceNumber}</title></head>
<body style="margin:0;padding:0;background:#f4f4f5;font-family:Arial,Helvetica,sans-serif;">
  <div style="max-width:560px;margin:0 auto;padding:24px;">
    <div style="background:#ffffff;border-radius:12px;padding:32px;border:1px solid #e4e4e7;">
      <h1 style="margin:0 0 4px;font-size:22px;color:#111;">${APP_NAME}</h1>
      <p style="margin:0 0 24px;color:#666;font-size:14px;">Factura de compra</p>

      <table style="width:100%;font-size:14px;border-collapse:collapse;">
        <tr>
          <td style="padding:4px 0;color:#666;">Factura n.º</td>
          <td style="padding:4px 0;text-align:right;font-weight:bold;">${this.escapeHtml(data.invoiceNumber)}</td>
        </tr>
        <tr>
          <td style="padding:4px 0;color:#666;">Fecha</td>
          <td style="padding:4px 0;text-align:right;">${this.formatDate(data.purchaseDate)}</td>
        </tr>
        <tr>
          <td style="padding:4px 0;color:#666;">Cliente</td>
          <td style="padding:4px 0;text-align:right;">${this.escapeHtml(data.customerName || data.to)}</td>
        </tr>
      </table>

      <hr style="border:none;border-top:1px solid #e4e4e7;margin:20px 0;">

      <table style="width:100%;font-size:14px;border-collapse:collapse;">
        <tr style="border-bottom:1px solid #e4e4e7;">
          <th style="padding:8px 0;text-align:left;color:#666;font-weight:600;">Concepto</th>
          <th style="padding:8px 0;text-align:right;color:#666;font-weight:600;">Importe</th>
        </tr>
        <tr>
          <td style="padding:12px 0;">
            <strong>${this.escapeHtml(data.productName)}</strong>
            ${data.productDescription ? `<br><span style="color:#666;font-size:13px;">${this.escapeHtml(data.productDescription)}</span>` : ''}
          </td>
          <td style="padding:12px 0;text-align:right;">${total}</td>
        </tr>
        ${taxRows}
        <tr style="border-top:2px solid #111;">
          <td style="padding:12px 0;font-weight:bold;font-size:16px;">Total</td>
          <td style="padding:12px 0;text-align:right;font-weight:bold;font-size:16px;">${total}</td>
        </tr>
      </table>

      <hr style="border:none;border-top:1px solid #e4e4e7;margin:20px 0;">

      <table style="width:100%;font-size:13px;color:#666;border-collapse:collapse;">
        <tr>
          <td style="padding:4px 0;">Forma de pago</td>
          <td style="padding:4px 0;text-align:right;">${this.platformLabel(data.platform)}</td>
        </tr>
        <tr>
          <td style="padding:4px 0;">ID de transaccion</td>
          <td style="padding:4px 0;text-align:right;word-break:break-all;">${this.escapeHtml(data.transactionId)}</td>
        </tr>
      </table>
    </div>

    <div style="text-align:center;color:#999;font-size:12px;padding:24px 0;line-height:1.6;">
      <p style="margin:0;">${SELLER_NAME} - ${SELLER_LOCATION}</p>
      <p style="margin:4px 0;">Factura simplificada generada automaticamente por ${APP_NAME}.</p>
      <p style="margin:4px 0;">Dudas sobre esta compra: <a href="mailto:${SUPPORT_EMAIL}" style="color:#666;">${SUPPORT_EMAIL}</a></p>
    </div>
  </div>
</body>
</html>`;
  }

  private buildReceiptText(data: PurchaseReceiptData): string {
    const total = this.formatAmount(data.amountCents, data.currency);
    const isEur = data.currency.toUpperCase() === 'EUR';
    const baseCents = Math.round(data.amountCents / (1 + VAT_RATE));
    const vatCents = data.amountCents - baseCents;

    const taxLines = isEur
      ? `Base imponible: ${this.formatAmount(baseCents, data.currency)}\nIVA (21%) incluido: ${this.formatAmount(vatCents, data.currency)}`
      : 'Impuestos: incluidos';

    return `${APP_NAME} - Factura de compra

Factura n.º: ${data.invoiceNumber}
Fecha: ${this.formatDate(data.purchaseDate)}
Cliente: ${data.customerName || data.to}

Concepto: ${data.productName}${data.productDescription ? `\n${data.productDescription}` : ''}
${taxLines}
Total: ${total}

Forma de pago: ${this.platformLabel(data.platform)}
ID de transaccion: ${data.transactionId}

${SELLER_NAME} - ${SELLER_LOCATION}
Factura simplificada generada automaticamente.
Soporte: ${SUPPORT_EMAIL}`;
  }
}
