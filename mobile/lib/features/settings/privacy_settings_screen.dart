import 'package:flutter/material.dart';
import 'legal_document_screen.dart';
import '../../services/email_service.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidad y Datos'),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: ListView(
        children: [
          const _SectionHeader('Tus Derechos de Privacidad'),
          _PrivacyOption(
            icon: Icons.visibility,
            title: 'Acceder a mis datos',
            description: 'Solicita una copia de tus datos personales',
            onTap: () => _showDataAccessDialog(context),
          ),
          _PrivacyOption(
            icon: Icons.edit,
            title: 'Corregir mis datos',
            description: 'Actualiza información incorrecta',
            onTap: () => _showDataCorrectionDialog(context),
          ),
          _PrivacyOption(
            icon: Icons.delete,
            title: 'Eliminar mis datos',
            description: 'Solicita la eliminación de tu cuenta y datos',
            onTap: () => _showDataDeletionDialog(context),
          ),
          _PrivacyOption(
            icon: Icons.file_download,
            title: 'Portar mis datos',
            description: 'Exporta tus datos en formato portátil',
            onTap: () => _showDataPortabilityDialog(context),
          ),
          _PrivacyOption(
            icon: Icons.block,
            title: 'Retirar consentimiento',
            description: 'Retira tu consentimiento para procesamiento de datos',
            onTap: () => _showConsentWithdrawalDialog(context),
          ),
          const Divider(),
          const _SectionHeader('Contacto de Privacidad'),
          ListTile(
            leading: const Icon(Icons.email, color: Color(0xFF4A90E2)),
            title: const Text('Email de Privacidad'),
            subtitle: const Text(EmailService.privacyEmail),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => EmailService.openEmailClient(
              recipient: EmailService.privacyEmail,
              subject: 'Consulta sobre privacidad',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.phone, color: Color(0xFF4A90E2)),
            title: const Text('Teléfono'),
            subtitle: const Text(EmailService.phoneNumber),
            onTap: () => EmailService.openEmailClient(
              recipient: EmailService.privacyEmail,
              subject: 'Consulta telefónica',
            ),
          ),
          const Divider(),
          const _SectionHeader('Documentos Legales'),
          _LegalDocument(
            icon: Icons.description,
            title: 'Política de Privacidad',
            onTap: () => _openDocument(context, 'Política de Privacidad', 'assets/legal/privacy_policy.md'),
          ),
          _LegalDocument(
            icon: Icons.gavel,
            title: 'Términos de Servicio',
            onTap: () => _openDocument(context, 'Términos de Servicio', 'assets/legal/terms_of_service.md'),
          ),
          _LegalDocument(
            icon: Icons.cookie,
            title: 'Política de Cookies',
            onTap: () => _openDocument(context, 'Política de Cookies', 'assets/legal/cookie_policy.md'),
          ),
        ],
      ),
    );
  }

  void _openDocument(BuildContext context, String title, String assetPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LegalDocumentScreen(
          title: title,
          assetPath: assetPath,
        ),
      ),
    );
  }

  void _showDataAccessDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Acceso a Datos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await EmailService.requestDataAccess(
                userName: nameController.text,
                userEmail: emailController.text,
                userPhone: phoneController.text,
              );
              Navigator.pop(context);
              _showSuccessMessage(context);
            },
            child: const Text('Enviar Solicitud'),
          ),
        ],
      ),
    );
  }

  void _showDataDeletionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Eliminación de Datos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Esta acción eliminará permanentemente tu cuenta y todos tus datos.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await EmailService.requestDataDeletion(
                userName: nameController.text,
                userEmail: emailController.text,
                userPhone: phoneController.text,
                reason: reasonController.text,
              );
              Navigator.pop(context);
              _showSuccessMessage(context);
            },
            child: const Text('Eliminar Datos'),
          ),
        ],
      ),
    );
  }

  void _showDataCorrectionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final fieldController = TextEditingController();
    final currentController = TextEditingController();
    final correctController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Corrección de Datos'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: fieldController,
                decoration: const InputDecoration(
                  labelText: 'Campo a corregir',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: currentController,
                decoration: const InputDecoration(
                  labelText: 'Valor actual',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: correctController,
                decoration: const InputDecoration(
                  labelText: 'Valor correcto',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await EmailService.requestDataCorrection(
                userName: nameController.text,
                userEmail: emailController.text,
                userPhone: phoneController.text,
                fieldToCorrect: fieldController.text,
                currentValue: currentController.text,
                correctValue: correctController.text,
              );
              Navigator.pop(context);
              _showSuccessMessage(context);
            },
            child: const Text('Enviar Solicitud'),
          ),
        ],
      ),
    );
  }

  void _showDataPortabilityDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Portabilidad de Datos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await EmailService.requestDataPortability(
                userName: nameController.text,
                userEmail: emailController.text,
                userPhone: phoneController.text,
              );
              Navigator.pop(context);
              _showSuccessMessage(context);
            },
            child: const Text('Enviar Solicitud'),
          ),
        ],
      ),
    );
  }

  void _showConsentWithdrawalDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final consentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirar Consentimiento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: consentController,
              decoration: const InputDecoration(
                labelText: 'Tipo de consentimiento',
                border: OutlineInputBorder(),
                hintText: 'Ej: procesamiento de datos, marketing, etc.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await EmailService.withdrawConsent(
                userName: nameController.text,
                userEmail: emailController.text,
                userPhone: phoneController.text,
                consentType: consentController.text,
              );
              Navigator.pop(context);
              _showSuccessMessage(context);
            },
            child: const Text('Retirar Consentimiento'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solicitud enviada correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4A90E2),
        ),
      ),
    );
  }
}

class _PrivacyOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _PrivacyOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4A90E2)),
      title: Text(title),
      subtitle: Text(description),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

class _LegalDocument extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _LegalDocument({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4A90E2)),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
