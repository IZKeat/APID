import 'package:flutter/material.dart';
// Common pages
import 'pages_common/login_page.dart';
import 'pages_common/qr_scanner.dart';
import 'pages_common/home_page.dart';
// import 'pages_common/qr_show_page.dart';
// Mobile Scanner Terminal
import 'pages_common/mobile_scanner_terminal.dart';

// Admin pages
// import 'pages_admin/admin_login.dart'; // Commented out as requested
import 'pages_admin/admin_dashboard.dart';

// Merchant pages
import 'pages_desktop/merchant_dashboard_desktop.dart';

// Guest pages
import 'pages_guest/guest_events_page.dart';
import 'pages_guest/guest_my_tickets_page.dart';
import 'pages_guest/guest_main_nav.dart';
import 'pages_guest/guest_profile_page.dart';

// User pages
// import 'pages_user/user_insights_page.dart';
// import 'pages_user/user_transactions_page.dart';
// import 'pages_user/user_activities_page.dart';
import 'pages_user/user_events_page.dart';
import 'pages_user/user_profile_page.dart';
import 'pages_user/my_ticket_details_page.dart';
import 'pages_user/digital_id_view.dart';
import 'pages_user/notification_inbox_page.dart';
import 'pages_user/help_support_page.dart';

// Old scanner temp file - no longer used
// import 'pages_common/mobile_pos_scanner_temp.dart';

/// Route names as constants to avoid typos
class Routes {
  // Private constructor to prevent instantiation
  const Routes._();

  // Route paths
  static const login = '/login';
  static const home = '/home';
  static const scanner = '/scanner';
  static const mobileScannerTerminal =
      '/mobile-scanner-terminal'; // Mobile Scanner Terminal route
  static const scannerTerminal =
      '/scanner-terminal'; // Alternative scanner-terminal route
  static const merchantDashboard = '/merchant-dashboard';
  static const adminLogin = '/admin-login';
  static const adminDashboard = '/admin-dashboard';

  // User Mode routes
  // static const userInsights = '/user_insights';
  // static const userTransactions = '/user_transactions';
  // static const userActivities = '/user_activities';
  static const userEvents = '/user_events';
  static const userProfile = '/user_profile';
  static const myTicketDetails = '/my_ticket_details';
  static const qrShow = '/qr_show';
  static const notificationInbox = '/notification_inbox';
  static const helpSupport = '/help_support';

  // Guest Mode routes
  static const guestMainNav = '/guest/main';
  static const guestEvents = '/guest/events';
  static const guestEventDetail = '/guest/event-detail';
  static const guestTicket = '/guest/ticket';
  static const guestMyTickets = '/guest/my-tickets';
  static const guestProfile = '/guest/profile';

  // Helper methods
  static String get initial => login;
  static bool isPublic(String route) =>
      route == login || route.startsWith('/guest');
}

/// Application's route configuration
final Map<String, WidgetBuilder> appRoutes = {
  Routes.login: (context) => const LoginPage(),
  Routes.home: (context) => const HomePage(),
  Routes.scanner: (context) => const QRScannerPage(),
  Routes.mobileScannerTerminal: (context) => const MobileScannerTerminal(),
  Routes.scannerTerminal: (context) => const MobileScannerTerminal(),
  Routes.merchantDashboard: (context) => const MerchantDashboardDesktop(),
  Routes.adminLogin: (context) => const LoginPage(), // Redirect to common login
  Routes.adminDashboard: (context) => const AdminDashboard(),

  // User Mode routes
  // Routes.userInsights: (context) => const UserInsightsPage(),
  // Routes.userTransactions: (context) => const UserTransactionsPage(),
  // Routes.userActivities: (context) => const UserActivitiesPage(),
  Routes.userEvents: (context) => const UserEventsPage(),
  Routes.userProfile: (context) => const UserProfilePage(),
  Routes.myTicketDetails: (context) => MyTicketDetailsPage(
    eventId: ModalRoute.of(context)!.settings.arguments as String,
  ),
  Routes.qrShow: (context) => const DigitalIdView(),
  Routes.notificationInbox: (context) => const NotificationInboxPage(),
  Routes.helpSupport: (context) => const HelpSupportPage(),

  // Guest Mode routes
  Routes.guestMainNav: (context) => const GuestMainNav(),
  Routes.guestEvents: (context) => const GuestEventsPage(),
  Routes.guestMyTickets: (context) => const GuestMyTicketsPage(),
  Routes.guestProfile: (context) => const GuestProfilePage(),
  // Note: guestEventDetail and guestTicket require parameters, handled via Navigator.push
};

/// Route guard function type
typedef RouteGuard = bool Function(BuildContext context);

/// Route configuration with additional metadata
class RouteConfig {
  final WidgetBuilder builder;
  final RouteGuard? guard;
  final String? redirectPath;

  const RouteConfig({required this.builder, this.guard, this.redirectPath});
}

/// Enhanced route configurations with guards
final Map<String, RouteConfig> enhancedRoutes = {
  Routes.login: RouteConfig(builder: (context) => const LoginPage()),
  Routes.scanner: RouteConfig(
    builder: (context) => const QRScannerPage(),
    guard: (context) => true,
    redirectPath: Routes.login,
  ),
  Routes.home: RouteConfig(
    builder: (context) => const HomePage(),
    guard: (context) => true,
    redirectPath: Routes.login,
  ),
};
