/// Central place for app-wide, non-secret configuration values.
class AppConstants {
  const AppConstants._();

  static const String appName = 'BoardEase';
  static const String tagline = 'Find your next home, hassle-free.';

  // Cloudinary unsigned upload configuration (no API secret is stored here).
  static const String cloudinaryCloudName = 'uwnu076w';
  static const String cloudinaryUploadPreset = 'Board_Ease';
  static const String cloudinaryUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload';

  // Upload limits.
  static const int maxImageBytes = 5 * 1024 * 1024;
  static const int imageMaxDimension = 1080;
  static const int imageQuality = 70;

  // Security / session.
  static const Duration inactivityTimeout = Duration(minutes: 15);
  static const int maxFailedLoginAttempts = 5;
  static const Duration loginLockoutDuration = Duration(seconds: 30);

  // Pagination.
  static const int pageSize = 20;

  // Firestore collections.
  static const String usersCollection = 'users';
  static const String roomsCollection = 'rooms';
  static const String reservationsCollection = 'reservations';
  static const String paymentsCollection = 'payments';
  static const String maintenanceCollection = 'maintenance';

  // PSGC API.
  static const String psgcBaseUrl = 'https://psgc.gitlab.io/api';

  // Field limits.
  static const int maxNameLength = 80;
  static const int maxTitleLength = 120;
  static const int maxDescriptionLength = 1000;
  static const int maxRulesLength = 1000;
  static const int maxStreetLength = 160;
  static const int maxAmenities = 20;
  static const int maxPhotos = 8;
}
