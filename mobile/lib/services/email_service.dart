import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class EmailService {
  static const String privacyEmail = 'privacy@roommatematch.com';
  static const String supportEmail = 'support@roommatematch.com';
  static const String legalEmail = 'legal@roommatematch.com';
  
  static const String privacyOfficerName = 'Victor Garcia Caballero';
  static const String phoneNumber = '+34 616 438 869';
  static const String address = 'Carrer Llunas, Barcelona, España';

  /// Send email using device email client (via url_launcher)
  static Future<void> sendEmail({
    required String recipient,
    required String subject,
    required String body,
    List<String>? cc,
    List<String>? bcc,
  }) async {
    try {
      await openEmailClient(
        recipient: recipient,
        subject: subject,
        body: body,
      );
    } catch (e) {
      debugPrint('Error sending email: $e');
      rethrow;
    }
  }

  /// Send privacy inquiry email
  static Future<void> sendPrivacyInquiry({
    required String userName,
    required String userEmail,
    required String userPhone,
    required String inquiry,
  }) async {
    final body = '''
Hola $privacyOfficerName,

Tengo una consulta sobre privacidad y datos personales en RoomMate Match.

Mis datos de contacto:
- Nombre: $userName
- Email: $userEmail
- Teléfono: $userPhone

Mi consulta:
$inquiry

Atentamente,
$userName
''';

    await sendEmail(
      recipient: privacyEmail,
      subject: 'Consulta sobre privacidad - RoomMate Match',
      body: body,
    );
  }

  /// Send data access request
  static Future<void> requestDataAccess({
    required String userName,
    required String userEmail,
    required String userPhone,
  }) async {
    final body = '''
Hola $privacyOfficerName,

Solicito acceso a mis datos personales almacenados en RoomMate Match.

Mis datos de contacto:
- Nombre: $userName
- Email: $userEmail
- Teléfono: $userPhone

Por favor, envíenme todos los datos personales que tienen sobre mí según el GDPR.

Atentamente,
$userName
''';

    await sendEmail(
      recipient: privacyEmail,
      subject: 'Solicitud de acceso a datos - RoomMate Match',
      body: body,
    );
  }

  /// Send data deletion request
  static Future<void> requestDataDeletion({
    required String userName,
    required String userEmail,
    required String userPhone,
    String? reason,
  }) async {
    final body = '''
Hola $privacyOfficerName,

Solicito la eliminación de mis datos personales y mi cuenta de RoomMate Match.

Mis datos de contacto:
- Nombre: $userName
- Email: $userEmail
- Teléfono: $userPhone

${reason != null ? 'Motivo de la solicitud:\n$reason' : ''}

Por favor, confirmen cuando se haya completado la eliminación.

Atentamente,
$userName
''';

    await sendEmail(
      recipient: privacyEmail,
      subject: 'Solicitud de eliminación de datos - RoomMate Match',
      body: body,
    );
  }

  /// Send data correction request
  static Future<void> requestDataCorrection({
    required String userName,
    required String userEmail,
    required String userPhone,
    required String fieldToCorrect,
    required String currentValue,
    required String correctValue,
  }) async {
    final body = '''
Hola $privacyOfficerName,

Solicito la corrección de mis datos personales en RoomMate Match.

Mis datos de contacto:
- Nombre: $userName
- Email: $userEmail
- Teléfono: $userPhone

Campo a corregir: $fieldToCorrect
Valor actual: $currentValue
Valor correcto: $correctValue

Por favor, actualicen esta información en mi cuenta.

Atentamente,
$userName
''';

    await sendEmail(
      recipient: privacyEmail,
      subject: 'Solicitud de corrección de datos - RoomMate Match',
      body: body,
    );
  }

  /// Send data portability request
  static Future<void> requestDataPortability({
    required String userName,
    required String userEmail,
    required String userPhone,
  }) async {
    final body = '''
Hola $privacyOfficerName,

Solicito la portabilidad de mis datos personales almacenados en RoomMate Match.

Mis datos de contacto:
- Nombre: $userName
- Email: $userEmail
- Teléfono: $userPhone

Por favor, envíenme todos mis datos personales en formato portátil (JSON) según el GDPR.

Atentamente,
$userName
''';

    await sendEmail(
      recipient: privacyEmail,
      subject: 'Solicitud de portabilidad de datos - RoomMate Match',
      body: body,
    );
  }

  /// Send consent withdrawal request
  static Future<void> withdrawConsent({
    required String userName,
    required String userEmail,
    required String userPhone,
    required String consentType,
  }) async {
    final body = '''
Hola $privacyOfficerName,

Retiro mi consentimiento para el procesamiento de mis datos personales en RoomMate Match.

Mis datos de contacto:
- Nombre: $userName
- Email: $userEmail
- Teléfono: $userPhone

Tipo de consentimiento que retiro: $consentType

Por favor, confirmen cuando se haya procesado esta retirada de consentimiento.

Atentamente,
$userName
''';

    await sendEmail(
      recipient: privacyEmail,
      subject: 'Retirada de consentimiento - RoomMate Match',
      body: body,
    );
  }

  /// Send support email
  static Future<void> sendSupportEmail({
    required String userName,
    required String userEmail,
    required String issue,
    String? orderId,
  }) async {
    final body = '''
Hola,

Necesito ayuda con RoomMate Match.

Mis datos:
- Nombre: $userName
- Email: $userEmail
${orderId != null ? '- ID de pedido: $orderId' : ''}

Mi problema:
$issue

Atentamente,
$userName
''';

    await sendEmail(
      recipient: supportEmail,
      subject: 'Soporte - RoomMate Match',
      body: body,
    );
  }

  /// Open email client directly
  static Future<void> openEmailClient({
    String? recipient,
    String? subject,
    String? body,
  }) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: recipient ?? privacyEmail,
        query: _encodeQueryParameters(
          subject: subject,
          body: body,
        ),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      debugPrint('Error opening email client: $e');
      rethrow;
    }
  }

  static String _encodeQueryParameters({String? subject, String? body}) {
    return [
      if (subject != null) 'subject=${Uri.encodeComponent(subject)}',
      if (body != null) 'body=${Uri.encodeComponent(body)}',
    ].join('&');
  }

  /// Get email signature
  static String getEmailSignature() {
    return '''
--
$privacyOfficerName
Privacy Officer
RoomMate Match

📍 $address
📞 $phoneNumber
📧 $privacyEmail

🔒 Tu privacidad es nuestra prioridad
''';
  }
}
