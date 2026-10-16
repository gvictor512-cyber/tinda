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
const SELLER_NAME = 'RoomMate Match';
const SELLER_LOCATION = 'Barcelona, España';
const SUPPORT_EMAIL = 'support@roommatematchapp.com';
const VAT_RATE = 0.21; // IVA aplicable en España para servicios digitales (incluido en el precio)

// Paleta de marca (espejo de AppTheme en mobile/lib/config/theme.dart)
const BRAND_BLUE_DARK = '#022C87';
const BRAND_BLUE = '#1FA5F0';
const BRAND_GREEN = '#50E3C2';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private readonly apiKey?: string;
  private readonly from: string;
  private readonly logoUrl?: string;
  private readonly sellerNif?: string;
  private readonly enabled: boolean;

  constructor(private readonly configService: ConfigService) {
    this.apiKey = this.configService.get<string>('RESEND_API_KEY');
    this.from =
      this.configService.get<string>('MAIL_FROM') ||
      `${APP_NAME} <${SUPPORT_EMAIL}>`;
    // Logo público para la cabecera del email (p. ej. servido por Firebase
    // Hosting). Si no está configurado se muestra solo el nombre de la app.
    this.logoUrl = this.configService.get<string>('MAIL_LOGO_URL') || undefined;
    // NIF del emisor: opcional en este resumen de compra (el documento fiscal
    // al consumidor lo emite la tienda). Se muestra solo si se configura.
    // Va por env var para no exponer datos fiscales personales en el repo.
    this.sellerNif = this.configService.get<string>('SELLER_NIF') || undefined;
    this.enabled =
      Boolean(this.apiKey) && !this.apiKey.includes('YOUR_RESEND_API_KEY');
    if (!this.enabled) {
      this.logger.warn(
        'RESEND_API_KEY no configurada: los emails de resumen de compra estan deshabilitados.',
      );
    }
  }

  /**
   * Envia el resumen de una compra al email del usuario.
   * Devuelve true si el proveedor acepto el envio, false en caso contrario.
   * Nunca lanza excepciones: el envio de email es best-effort.
   */
  async sendPurchaseReceipt(data: PurchaseReceiptData): Promise<boolean> {
    if (!this.enabled) {
      this.logger.log(
        `Resumen de compra ${data.invoiceNumber} no enviado (servicio de email deshabilitado)`,
      );
      return false;
    }

    return this.send({
      to: data.to,
      subject: `Tu resumen de compra de ${APP_NAME} - ${data.invoiceNumber}`,
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
      return new Intl.NumberFormat('es-ES', {
        style: 'currency',
        currency,
      }).format(cents / 100);
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
    const greeting = data.customerName
      ? `Gracias por tu compra, ${this.escapeHtml(data.customerName)}.`
      : 'Gracias por tu compra.';

    const logoBlock = this.logoUrl
      ? `<img src="${this.escapeHtml(this.logoUrl)}" alt="${APP_NAME}" width="56" height="56" style="display:block;border-radius:14px;border:0;">`
      : '';

    const taxRows = isEur
      ? `
            <tr>
              <td style="padding:8px 0;color:#64748B;font-size:14px;">Base imponible</td>
              <td style="padding:8px 0;text-align:right;font-size:14px;color:#1E293B;">${this.formatAmount(baseCents, data.currency)}</td>
            </tr>
            <tr>
              <td style="padding:8px 0;color:#64748B;font-size:14px;">IVA (21%) incluido</td>
              <td style="padding:8px 0;text-align:right;font-size:14px;color:#1E293B;">${this.formatAmount(vatCents, data.currency)}</td>
            </tr>`
      : `
            <tr>
              <td style="padding:8px 0;color:#64748B;font-size:14px;">Impuestos</td>
              <td style="padding:8px 0;text-align:right;font-size:14px;color:#1E293B;">Incluidos</td>
            </tr>`;

    return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Resumen de compra ${this.escapeHtml(data.invoiceNumber)} - ${APP_NAME}</title>
</head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:'Segoe UI',Arial,Helvetica,sans-serif;">
  <div style="display:none;max-height:0;overflow:hidden;">Tu resumen de compra ${this.escapeHtml(data.invoiceNumber)} de ${APP_NAME} - ${total}</div>
  <div style="max-width:560px;margin:0 auto;padding:24px 16px;">

    <!-- Cabecera de marca -->
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;">
      <tr>
        <td bgcolor="${BRAND_BLUE_DARK}" style="background:linear-gradient(135deg,${BRAND_BLUE_DARK} 0%,${BRAND_BLUE} 100%);background-color:${BRAND_BLUE_DARK};border-radius:20px 20px 0 0;padding:32px;text-align:center;">
          ${logoBlock}
          ${logoBlock ? '<div style="height:14px;"></div>' : ''}
          <div style="font-size:24px;font-weight:800;color:#ffffff;letter-spacing:-0.5px;">${APP_NAME}</div>
          <div style="margin-top:6px;font-size:13px;font-weight:600;color:${BRAND_GREEN};letter-spacing:1.5px;text-transform:uppercase;">Resumen de compra</div>
        </td>
      </tr>
    </table>

    <!-- Cuerpo -->
    <div style="background:#ffffff;padding:32px;border-left:1px solid #E2E8F0;border-right:1px solid #E2E8F0;">
      <p style="margin:0 0 4px;font-size:16px;color:#1E293B;font-weight:600;">${greeting}</p>
      <p style="margin:0 0 24px;font-size:14px;color:#64748B;line-height:1.5;">Aqui tienes el resumen de tu compra. Tu producto ya esta activo en tu cuenta.</p>

      <table style="width:100%;font-size:14px;border-collapse:collapse;">
        <tr>
          <td style="padding:6px 0;color:#64748B;">Compra n.º</td>
          <td style="padding:6px 0;text-align:right;font-weight:bold;color:#1E293B;">${this.escapeHtml(data.invoiceNumber)}</td>
        </tr>
        <tr>
          <td style="padding:6px 0;color:#64748B;">Fecha</td>
          <td style="padding:6px 0;text-align:right;color:#1E293B;">${this.formatDate(data.purchaseDate)}</td>
        </tr>
        <tr>
          <td style="padding:6px 0;color:#64748B;">Cliente</td>
          <td style="padding:6px 0;text-align:right;color:#1E293B;">${this.escapeHtml(data.customerName || data.to)}</td>
        </tr>
      </table>

      <hr style="border:none;border-top:1px solid #E2E8F0;margin:20px 0;">

      <table style="width:100%;font-size:14px;border-collapse:collapse;">
        <tr>
          <th style="padding:8px 0;text-align:left;color:${BRAND_BLUE};font-weight:700;font-size:12px;letter-spacing:1px;text-transform:uppercase;border-bottom:1px solid #E2E8F0;">Concepto</th>
          <th style="padding:8px 0;text-align:right;color:${BRAND_BLUE};font-weight:700;font-size:12px;letter-spacing:1px;text-transform:uppercase;border-bottom:1px solid #E2E8F0;">Importe</th>
        </tr>
        <tr>
          <td style="padding:14px 0;">
            <strong style="color:#1E293B;">${this.escapeHtml(data.productName)}</strong>
            ${data.productDescription ? `<br><span style="color:#64748B;font-size:13px;">${this.escapeHtml(data.productDescription)}</span>` : ''}
          </td>
          <td style="padding:14px 0;text-align:right;color:#1E293B;">${total}</td>
        </tr>
        ${taxRows}
        <tr>
          <td style="padding:14px 0 0;font-weight:800;font-size:18px;color:#1E293B;border-top:2px solid ${BRAND_BLUE};">Total</td>
          <td style="padding:14px 0 0;text-align:right;font-weight:800;font-size:18px;color:${BRAND_BLUE_DARK};border-top:2px solid ${BRAND_BLUE};">${total}</td>
        </tr>
      </table>
    </div>

    <!-- Detalles de pago -->
    <div style="background:#F8FAFC;padding:20px 32px;border:1px solid #E2E8F0;border-top:none;border-radius:0 0 20px 20px;">
      <table style="width:100%;font-size:13px;color:#64748B;border-collapse:collapse;">
        <tr>
          <td style="padding:4px 0;">Forma de pago</td>
          <td style="padding:4px 0;text-align:right;color:#1E293B;font-weight:600;">${this.platformLabel(data.platform)}</td>
        </tr>
        <tr>
          <td style="padding:4px 0;">ID de transaccion</td>
          <td style="padding:4px 0;text-align:right;word-break:break-all;color:#1E293B;font-weight:600;">${this.escapeHtml(data.transactionId)}</td>
        </tr>
      </table>
    </div>

    <div style="text-align:center;color:#94A3B8;font-size:12px;padding:24px 0;line-height:1.6;">
      <p style="margin:0;">${SELLER_NAME} - ${SELLER_LOCATION}</p>
      ${this.sellerNif ? `<p style="margin:4px 0;">NIF: ${this.escapeHtml(this.sellerNif)}</p>` : ''}
      <p style="margin:4px 0;">Resumen de compra generado automaticamente por ${APP_NAME}.</p>
      <p style="margin:4px 0;">Dudas sobre esta compra: <a href="mailto:${SUPPORT_EMAIL}" style="color:${BRAND_BLUE};text-decoration:none;">${SUPPORT_EMAIL}</a></p>
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

    return `${APP_NAME} - Resumen de compra

Compra n.º: ${data.invoiceNumber}
Fecha: ${this.formatDate(data.purchaseDate)}
Cliente: ${data.customerName || data.to}

Concepto: ${data.productName}${data.productDescription ? `\n${data.productDescription}` : ''}
${taxLines}
Total: ${total}

Forma de pago: ${this.platformLabel(data.platform)}
ID de transaccion: ${data.transactionId}

${SELLER_NAME} - ${SELLER_LOCATION}
${this.sellerNif ? `NIF: ${this.sellerNif}\n` : ''}Resumen de compra generado automaticamente.
Soporte: ${SUPPORT_EMAIL}`;
  }
}
