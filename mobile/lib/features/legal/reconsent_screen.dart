import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../config/legal_constants.dart';
import '../../config/theme.dart';
import '../settings/legal_document_screen.dart';

/// Blocking screen shown when the stored consent version is older than the
/// current terms/privacy version. The user must re-accept to continue.
class ReconsentScreen extends StatefulWidget {
  const ReconsentScreen({super.key});

  @override
  State<ReconsentScreen> createState() => _ReconsentScreenState();
}

class _ReconsentScreenState extends State<ReconsentScreen> {
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _saving = false;

  Future<void> _accept() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'consent.acceptedTermsAt': FieldValue.serverTimestamp(),
        'consent.acceptedPrivacyAt': FieldValue.serverTimestamp(),
        'consent.termsVersion': LegalConstants.currentTermsVersion,
        'consent.privacyVersion': LegalConstants.currentPrivacyVersion,
      });
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/main', (_) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _acceptedTerms && _acceptedPrivacy;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gavel_rounded,
                  size: 64, color: AppTheme.primaryBlue),
              const SizedBox(height: 24),
              const Text(
                'Hemos actualizado nuestras condiciones',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Para seguir usando RoomMate Match necesitas revisar y '
                'aceptar la versión actual de los documentos legales.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                title: Wrap(
                  children: [
                    const Text('Acepto los '),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LegalDocumentScreen(
                            assetPath: 'assets/legal/terms_of_service.md',
                            title: 'Términos de Servicio',
                          ),
                        ),
                      ),
                      child: const Text('Términos de Servicio',
                          style: TextStyle(color: AppTheme.primaryBlue)),
                    ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: _acceptedPrivacy,
                onChanged: (v) => setState(() => _acceptedPrivacy = v ?? false),
                title: Wrap(
                  children: [
                    const Text('Acepto la '),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LegalDocumentScreen(
                            assetPath: 'assets/legal/privacy_policy.md',
                            title: 'Política de Privacidad',
                          ),
                        ),
                      ),
                      child: const Text('Política de Privacidad',
                          style: TextStyle(color: AppTheme.primaryBlue)),
                    ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canContinue && !_saving ? _accept : null,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
