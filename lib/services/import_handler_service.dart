import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'guide_book_service.dart';

/// Handles deep links and file imports
/// Supports:
/// 1. Deep links: geezerguides://import?data=<base64-encoded-json>
/// 2. File sharing: .geezerguide files from email/other apps
class ImportHandlerService {
  final GuideBookService _guideBookService;
  StreamSubscription? _deepLinkSubscription;
  StreamSubscription? _fileShareSubscription;

  ImportHandlerService(this._guideBookService);

  /// Initialize import handlers
  Future<void> initialize() async {
    debugPrint('🔵 ImportHandler: Initializing...');

    // Handle deep links (geezerguides://import?data=...)
    _initDeepLinkHandler();

    // Handle shared files (.geezerguide from email/other apps)
    _initFileShareHandler();

    // Check for initial deep link (app opened from link)
    _checkInitialDeepLink();

    // Check for initial shared file (app opened from share)
    _checkInitialSharedFile();
  }

  /// Handle deep links while app is running
  void _initDeepLinkHandler() {
    _deepLinkSubscription = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        debugPrint('🔵 ImportHandler: Received deep link: $uri');
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      debugPrint('❌ ImportHandler: Deep link error: $err');
    });
  }

  /// Handle shared files while app is running
  void _initFileShareHandler() {
    // Listen for files shared while app is running
    _fileShareSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      if (files.isNotEmpty) {
        debugPrint(
            '🔵 ImportHandler: Received ${files.length} shared file(s)');
        for (var file in files) {
          _handleSharedFile(file.path);
        }
      }
    }, onError: (err) {
      debugPrint('❌ ImportHandler: File share error: $err');
    });
  }

  /// Check if app was opened from a deep link
  Future<void> _checkInitialDeepLink() async {
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        debugPrint(
            '🔵 ImportHandler: App opened with deep link: $initialUri');
        _handleDeepLink(initialUri);
      }
    } on PlatformException catch (e) {
      debugPrint('❌ ImportHandler: Failed to get initial deep link: $e');
    }
  }

  /// Check if app was opened from a shared file
  Future<void> _checkInitialSharedFile() async {
    try {
      final files = await ReceiveSharingIntent.instance.getInitialMedia();
      if (files.isNotEmpty) {
        debugPrint(
            '🔵 ImportHandler: App opened with ${files.length} shared file(s)');
        for (var file in files) {
          _handleSharedFile(file.path);
        }
        // Clear the shared files after handling
        ReceiveSharingIntent.instance.reset();
      }
    } catch (e) {
      debugPrint('❌ ImportHandler: Failed to get initial shared files: $e');
    }
  }

  /// Handle a deep link
  Future<void> _handleDeepLink(Uri uri) async {
    // Expected format: geezerguides://import?data=<base64-encoded-json>
    if (uri.scheme != 'geezerguides' || uri.host != 'import') {
      debugPrint('⚠️ ImportHandler: Unknown deep link format: $uri');
      return;
    }

    final dataParam = uri.queryParameters['data'];
    if (dataParam == null || dataParam.isEmpty) {
      debugPrint('⚠️ ImportHandler: Missing data parameter in deep link');
      return;
    }

    try {
      // Decode base64 to JSON string
      final jsonString = utf8.decode(base64.decode(dataParam));
      debugPrint('🔵 ImportHandler: Decoded JSON from deep link');

      // Import via GuideBookService
      final success = await _guideBookService.importFromJson(jsonString);
      if (success) {
        debugPrint('✅ ImportHandler: Successfully imported from deep link');
      } else {
        debugPrint('❌ ImportHandler: Failed to import from deep link');
      }
    } catch (e) {
      debugPrint('❌ ImportHandler: Error processing deep link: $e');
    }
  }

  /// Handle a shared file
  Future<void> _handleSharedFile(String filePath) async {
    debugPrint('🔵 ImportHandler: Processing shared file: $filePath');

    // Verify it's a .geezerguide file
    if (!filePath.toLowerCase().endsWith('.geezerguide')) {
      debugPrint('⚠️ ImportHandler: Not a .geezerguide file: $filePath');
      return;
    }

    try {
      // Import via GuideBookService
      final success = await _guideBookService.importGuideBook(filePath);
      if (success) {
        debugPrint('✅ ImportHandler: Successfully imported file: $filePath');
      } else {
        debugPrint('❌ ImportHandler: Failed to import file: $filePath');
      }
    } catch (e) {
      debugPrint('❌ ImportHandler: Error processing file: $e');
    }
  }

  /// Clean up
  void dispose() {
    _deepLinkSubscription?.cancel();
    _fileShareSubscription?.cancel();
    debugPrint('🔵 ImportHandler: Disposed');
  }
}
