// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get permissionLocationTitle => 'Location';

  @override
  String get permissionLocationDescription =>
      'We use your location to show you nearby roommates and flats.';

  @override
  String get permissionCameraTitle => 'Camera';

  @override
  String get permissionCameraDescription =>
      'RoomMate Match needs camera access so you can add profile photos and verify your identity.';

  @override
  String get permissionNotificationsTitle => 'Notifications';

  @override
  String get permissionNotificationsDescription =>
      'We notify you of matches, messages and important updates.';

  @override
  String get permissionPhotosTitle => 'Gallery';

  @override
  String get permissionPhotosDescription =>
      'We access your gallery so you can select profile photos.';

  @override
  String get cancel => 'Cancel';

  @override
  String get allow => 'Allow';
}
