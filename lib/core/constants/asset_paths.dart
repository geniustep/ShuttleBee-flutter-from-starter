/// Asset paths constants
class AssetPaths {
  AssetPaths._();

  // === Base Paths ===
  static const String _imagesPath = 'assets/images';
  static const String _iconsPath = 'assets/icons';
  static const String _animationsPath = 'assets/animations';

  // === Images ===
  static const String logo = '$_imagesPath/logo.png';
  static const String logoWhite = '$_imagesPath/logo_white.png';
  static const String placeholder = '$_imagesPath/placeholder.png';
  static const String emptyState = '$_imagesPath/empty_state.png';
  static const String errorState = '$_imagesPath/error_state.png';
  static const String offlineState = '$_imagesPath/offline_state.png';
  static const String noConnection = '$_imagesPath/no_connection.png';
  static const String loginBg = '$_imagesPath/login_bg.png';

  // === Icons (SVG) ===
  static const String iconHome = '$_iconsPath/home.svg';
  static const String iconDashboard = '$_iconsPath/dashboard.svg';
  static const String iconSettings = '$_iconsPath/settings.svg';
  static const String iconNotification = '$_iconsPath/notification.svg';
  static const String iconSearch = '$_iconsPath/search.svg';
  static const String iconProfile = '$_iconsPath/profile.svg';
  static const String iconLogout = '$_iconsPath/logout.svg';
  static const String iconSync = '$_iconsPath/sync.svg';
  static const String iconOffline = '$_iconsPath/offline.svg';

  // === Animations (Lottie) ===
  static const String animationLoading = '$_animationsPath/loading.json';
  static const String animationSuccess = '$_animationsPath/success.json';
  static const String animationError = '$_animationsPath/error.json';
  static const String animationEmpty = '$_animationsPath/empty.json';
  static const String animationSync = '$_animationsPath/sync.json';
  static const String animationOffline = '$_animationsPath/offline.json';
}
