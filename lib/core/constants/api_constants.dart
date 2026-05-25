class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://fitviz.in/api';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';
  static const String updateProfile = '/auth/profile';
  static const String updateFcm = '/auth/fcm';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';

  // Gyms (public)
  static const String activeGyms = '/gyms';
  static const String gymByToken = '/gyms/by-token';

  // Fitness plans
  static const String todayPlan = '/fitness-plans/today';
  static const String planHistory = '/fitness-plans/history';

  // Attendance
  static const String checkin = '/attendance/checkin';
  static const String checkout = '/attendance/checkout';
  static const String myAttendance = '/attendance/my';

  // Subscriptions
  static const String mySubscription = '/subscriptions/my';
  static const String mySubscriptionHistory = '/subscriptions/my/history';
  static const String subscriptionPlans = '/subscriptions/plans';

  // Classes
  static const String classSchedule = '/classes/member/schedule';
  static const String bookClass = '/classes/member/book';
  static const String myBookings = '/classes/member/my-bookings';
  static const String cancelBooking = '/classes/member/bookings';

  // Body metrics
  static const String bodyMetrics = '/members/metrics';
  static const String myMetrics = '/members/metrics/my';

  // Achievements
  static const String myAchievements = '/members/achievements/my';
  static const String addAchievement = '/members/achievements';

  // Trainer assigned to me
  static const String trainerMeasurements = '/trainer/members';
  static const String trainerPhotos = '/trainer/members';

  // Payments
  static const String createOrder = '/payment/create-order';
  static const String verifyPayment = '/payment/verify';
  static const String paymentHistory = '/payment/history';

  // Invoices
  static const String invoices = '/invoices';

  // Gym info
  static const String myGymInfo = '/gyms/mine';

  // Public content
  static const String activeOffers = '/offers/active';
  static const String activeAnnouncements = '/announcements/active';

  // Referrals
  static const String referralCode = '/referrals/my-code';

  // Feedback
  static const String feedback = '/feedback';
  static const String myFeedback = '/feedback/mine';

  // Push & Notifications
  static const String subscribe = '/notifications/subscribe';
  static const String unsubscribe = '/notifications/unsubscribe';

  // WhatsApp opt-in
  static const String whatsappOptIn = '/members'; // PATCH /:id/whatsapp

  // Group classes booking
  static String cancelBookingById(String id) => '/classes/member/bookings/$id';
  static String invoiceById(String id) => '/invoices/$id';
  static String invoicePdf(String id) => '/invoices/$id/pdf';
  static String memberProfile(String id) => '/members/$id';
  static String trainerMeasurementsFor(String memberId) =>
      '/trainer/members/$memberId/measurements';
  static String trainerPhotosFor(String memberId) =>
      '/trainer/members/$memberId/photos';
}
