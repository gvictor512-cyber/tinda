// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get permissionLocationTitle => 'Ubicación';

  @override
  String get permissionLocationDescription =>
      'Usamos tu ubicación para mostrarte compañeros y pisos cercanos según tus preferencias.';

  @override
  String get permissionCameraTitle => 'Cámara';

  @override
  String get permissionCameraDescription =>
      'RoomMate Match necesita acceso a la cámara para que puedas añadir fotos de perfil y verificar tu identidad.';

  @override
  String get permissionNotificationsTitle => 'Notificaciones';

  @override
  String get permissionNotificationsDescription =>
      'Te avisamos de matches, mensajes y novedades importantes.';

  @override
  String get permissionPhotosTitle => 'Galería';

  @override
  String get permissionPhotosDescription =>
      'Accedemos a tu galería para que puedas seleccionar fotos de perfil.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get allow => 'Permitir';
}
