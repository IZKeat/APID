import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import '../routes.dart';
import '../pages_user/event_details_page.dart';

/// 🔗 Deep Link Service
/// Handles incoming links (qrvid:// or https://) and navigates to the appropriate screen.
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Initialize Deep Linking
  Future<void> init(BuildContext context) async {
    // 🛡️ Windows Safety Check
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('🖥️ Deep Links skipped on Desktop (Not supported)');
      return;
    }

    try {
      // 1. Handle Initial Link (App was closed)
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 Initial Deep Link: $initialUri');
        _handleLink(context, initialUri);
      }

      // 2. Listen for Stream Links (App is in background/foreground)
      _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          debugPrint('🔗 Stream Deep Link: $uri');
          _handleLink(context, uri);
        }
      }, onError: (err) {
        debugPrint('❌ Deep Link Error: $err');
      });

    } catch (e) {
      debugPrint('❌ Deep Link Init Error: $e');
    }
  }

  /// Handle the parsed URI and navigate
  void _handleLink(BuildContext context, Uri uri) {
    // Example: qrvid://event?id=123
    // Example: https://qr-virtual-identity.web.app/guest/event-detail?id=123
    
    final String path = uri.path;
    final Map<String, String> params = uri.queryParameters;

    debugPrint('🔗 Handling Link - Path: $path, Params: $params');

    // 1. Event Details Route
    if (path.contains('event') || path.contains('event-detail')) {
      final String? eventId = params['id'];
      if (eventId != null) {
        debugPrint('🚀 Navigating to Event ID: $eventId');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EventDetailsPage(eventId: eventId),
          ),
        );
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
