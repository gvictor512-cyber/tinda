/// Legal document versioning.
/// Bump CURRENT_TERMS_VERSION whenever terms/privacy change — users whose
/// stored consent version differs will be asked to re-accept.
class LegalConstants {
  LegalConstants._();

  static const String currentTermsVersion = '1.0';
  static const String currentPrivacyVersion = '1.0';
}
