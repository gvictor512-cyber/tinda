import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      'question': '¿Cómo funciona RoomMate Match?',
      'answer': 'Te mostramos perfiles de compañeros de piso compatibles según tus preferencias.',
    },
    {
      'question': '¿Cómo me suscribo a Premium?',
      'answer': 'Ve al apartado Premium en tu perfil y elige el plan que prefieras.',
    },
    {
      'question': '¿Puedo editar mi perfil?',
      'answer': 'Sí, desde el menú "Editar perfil" puedes modificar tus datos.',
    },
    {
      'question': '¿Cómo contacto con soporte?',
      'answer': 'Escríbenos a support@roommatematchapp.com.',
    },
  ];

  void _showSupportDialog(BuildContext context) {
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contactar con soporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: 'Asunto'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Mensaje'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final subject = subjectController.text.trim();
              final body = bodyController.text.trim();

              if (subject.isEmpty || body.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rellena el asunto y el mensaje.')),
                );
                return;
              }

              final user = FirebaseAuth.instance.currentUser;
              await FirebaseFirestore.instance.collection('support_messages').add({
                'userId': user?.uid,
                'email': user?.email,
                'subject': subject,
                'body': body,
                'timestamp': FieldValue.serverTimestamp(),
                'status': 'open',
              });

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mensaje enviado al equipo de soporte.')),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda y soporte')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const SizedBox(height: 8),
            const Text(
              'Preguntas frecuentes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ..._faqs.map((faq) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ExpansionTile(
                    title: Text(faq['question']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['answer']!,
                          style: const TextStyle(color: AppTheme.textLightSecondary),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            const Text(
              '¿Necesitas más ayuda?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email_outlined, color: AppTheme.primaryBlue),
              title: const Text('Contactar con soporte'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showSupportDialog(context),
            ),
            const SizedBox(height: 24),
            const Text(
              '© 2026 RoomMate Match. All rights reserved.',
              style: TextStyle(fontSize: 12, color: AppTheme.textLightSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
