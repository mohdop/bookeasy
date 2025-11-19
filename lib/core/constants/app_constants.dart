class AppConstants {
  // App Info
  static const String appName = 'BookEasy';
  static const String appVersion = '1.0.0';
  
  // Timing
  static const int defaultSlotDuration = 30; // minutes
  static const int maxBookingDaysInAdvance = 90; // days
  
  // Limits
  static const int maxServicesPerBusiness = 50;
  static const int maxAppointmentsPerDay = 100;
  
  // Business Categories Icons
  static const Map<String, String> categoryIcons = {
    'barber': '💈',
    'coach': '🏋️',
    'nail_artist': '💅',
    'tutor': '📚',
    'other': '💼',
  };
}