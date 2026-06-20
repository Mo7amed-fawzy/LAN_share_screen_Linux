class AppConstants {
  AppConstants._();

  static const String appName = 'ScreenShare';

  static const int defaultMaxParticipants = 10;
  static const int initialTargetUsers = 4;

  static const double focusedVideoMinWidth = 640;
  static const double focusedVideoMinHeight = 360;
  static const double thumbnailWidth = 160;
  static const double thumbnailHeight = 90;

  static const int focusedFps = 30;
  static const int thumbnailFps = 5;

  static const int focusedMaxBitrate = 2_500_000;
  static const int thumbnailMaxBitrate = 150_000;

  static const int reconnectionMaxRetries = 5;
  static const Duration reconnectionDelay = Duration(seconds: 2);

  static const Duration animateTransitionDuration = Duration(milliseconds: 300);

  static const double thumbnailBarHeight = 100;
  static const double thumbnailGap = 8;
}
