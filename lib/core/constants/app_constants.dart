import '../../flavors/flavor_config.dart';

class AppConstants {
  AppConstants._();

  // Delegates to FlavorConfig so all flavors get the correct app name/tagline.
  static String get appName => FlavorConfig.instance.appName;
  static String get appTagline => FlavorConfig.instance.appTagline;

  // SharedPreferences keys (non-sensitive only)
  static const String keyGymId = 'gym_id';
  static const String keyGymName = 'gym_name';
  static const String keyTheme = 'theme';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyLastDashboardJson = 'last_dashboard';
  static const String keyLastAttendanceJson = 'last_attendance';

  // App lock timeout in seconds
  static const int appLockTimeoutSeconds = 300; // 5 minutes

  // Pagination
  static const int defaultPageSize = 20;

  // Razorpay
  static const String razorpayKeyId = 'rzp_live_XXXXXXXXXXXXXXXX'; // replace with actual key
  static const String razorpayCurrency = 'INR';

  // Date formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String apiDateFormat = 'yyyy-MM-dd';
}
