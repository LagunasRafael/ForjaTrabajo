import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class SpanishAssetPickerTextDelegate extends AssetPickerTextDelegate {
  const SpanishAssetPickerTextDelegate();

  @override String get languageCode => 'es';
  @override String get confirm => 'Confirmar';
  @override String get cancel => 'Cancelar';
  @override String get edit => 'Editar';
  @override String get gifIndicator => 'GIF';
  @override String get livePhotoIndicator => 'LIVE';
  @override String get loadFailed => 'Error de carga';
  @override String get original => 'Original';
  @override String get preview => 'Vista previa';
  @override String get select => 'Seleccionar';
  @override String get emptyList => 'Lista vacía';
  @override String get unSupportedAssetType => 'Formato no soportado';
  @override String get unableToAccessAll => 'No se puede acceder a todos los archivos';
  @override String get viewingLimitedAssetsTip => 'Mostrando solo archivos permitidos';
  @override String get changeAccessibleLimitedAssets => 'Permitir más archivos';
  @override String get accessAllTip => 'Otorga permisos para ver toda la galería.';
  @override String get goToSystemSettings => 'Ir a ajustes';
  @override String get accessLimitedAssets => 'Continuar con acceso limitado';
  @override String get accessiblePathName => 'Archivos accesibles';
  @override String get sTypeAudioLabel => 'Audio';
  @override String get sTypeImageLabel => 'Imagen';
  @override String get sTypeVideoLabel => 'Video';
  @override String get sTypeOtherLabel => 'Otro media';
  @override String get sActionPlayHint => 'Reproducir';
  @override String get sActionPreviewHint => 'Vista previa';
  @override String get sActionSelectHint => 'Seleccionar';
  @override String get sActionSwitchPathLabel => 'Cambiar álbum';
  @override String get sActionUseCameraHint => 'Usar cámara';
  @override String get sNameDurationLabel => 'Duración';
  @override String get sUnitAssetCountLabel => 'Cantidad';
}
