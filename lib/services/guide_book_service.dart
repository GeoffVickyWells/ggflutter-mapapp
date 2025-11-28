import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/guide_book.dart';

/// Service to manage guide book files (.geezerguide)
/// Handles importing, storing, and loading guide books with waypoints
class GuideBookService extends ChangeNotifier {
  List<GuideBook> _guideBooks = [];
  GuideBook? _activeGuideBook;

  List<GuideBook> get guideBooks => _guideBooks;
  GuideBook? get activeGuideBook => _activeGuideBook;

  /// Initialize - load saved guide books from storage
  Future<void> initialize() async {
    debugPrint('🔵 GuideBookService: Initializing...');
    await _loadSavedGuideBooks();
  }

  /// Import a .geezerguide file
  Future<bool> importGuideBook(String filePath) async {
    try {
      debugPrint('🔵 GuideBookService: Importing from $filePath');

      // Read file content
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ GuideBookService: File does not exist');
        return false;
      }

      final jsonContent = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(jsonContent);

      // Parse guide book
      final guideBook = GuideBook.fromJson(json);
      debugPrint(
          '✅ GuideBookService: Parsed guide book: ${guideBook.title} with ${guideBook.waypointCount} waypoints');

      // Check if already imported
      final existingIndex =
          _guideBooks.indexWhere((gb) => gb.id == guideBook.id);
      if (existingIndex != -1) {
        debugPrint('⚠️ GuideBookService: Guide book already exists, replacing');
        _guideBooks[existingIndex] = guideBook;
      } else {
        _guideBooks.add(guideBook);
      }

      // Save to local storage
      await _saveGuideBook(guideBook);

      // Set as active if it's the first one
      if (_activeGuideBook == null) {
        _activeGuideBook = guideBook;
        await _saveActiveGuideBookId(guideBook.id);
      }

      notifyListeners();
      debugPrint('✅ GuideBookService: Import complete');
      return true;
    } catch (e) {
      debugPrint('❌ GuideBookService: Import failed: $e');
      return false;
    }
  }

  /// Import from JSON string (for deep links)
  Future<bool> importFromJson(String jsonContent) async {
    try {
      debugPrint('🔵 GuideBookService: Importing from JSON string');

      final Map<String, dynamic> json = jsonDecode(jsonContent);
      final guideBook = GuideBook.fromJson(json);

      // Check if already imported
      final existingIndex =
          _guideBooks.indexWhere((gb) => gb.id == guideBook.id);
      if (existingIndex != -1) {
        _guideBooks[existingIndex] = guideBook;
      } else {
        _guideBooks.add(guideBook);
      }

      await _saveGuideBook(guideBook);

      if (_activeGuideBook == null) {
        _activeGuideBook = guideBook;
        await _saveActiveGuideBookId(guideBook.id);
      }

      notifyListeners();
      debugPrint('✅ GuideBookService: Import from JSON complete');
      return true;
    } catch (e) {
      debugPrint('❌ GuideBookService: Import from JSON failed: $e');
      return false;
    }
  }

  /// Set active guide book
  void setActiveGuideBook(GuideBook guideBook) {
    _activeGuideBook = guideBook;
    _saveActiveGuideBookId(guideBook.id);
    notifyListeners();
    debugPrint('✅ GuideBookService: Set active guide book: ${guideBook.title}');
  }

  /// Delete a guide book
  Future<void> deleteGuideBook(GuideBook guideBook) async {
    _guideBooks.removeWhere((gb) => gb.id == guideBook.id);

    // Delete from storage
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/guides/${guideBook.id}.json');
    if (await file.exists()) {
      await file.delete();
    }

    // Clear active if it was the deleted one
    if (_activeGuideBook?.id == guideBook.id) {
      _activeGuideBook = _guideBooks.isNotEmpty ? _guideBooks.first : null;
      if (_activeGuideBook != null) {
        await _saveActiveGuideBookId(_activeGuideBook!.id);
      }
    }

    notifyListeners();
    debugPrint('✅ GuideBookService: Deleted guide book: ${guideBook.title}');
  }

  /// Save guide book to local storage
  Future<void> _saveGuideBook(GuideBook guideBook) async {
    final directory = await getApplicationDocumentsDirectory();
    final guidesDir = Directory('${directory.path}/guides');

    // Create guides directory if it doesn't exist
    if (!await guidesDir.exists()) {
      await guidesDir.create(recursive: true);
    }

    final file = File('${guidesDir.path}/${guideBook.id}.json');
    final jsonString = jsonEncode(guideBook.toJson());
    await file.writeAsString(jsonString);

    debugPrint('✅ GuideBookService: Saved guide book to ${file.path}');
  }

  /// Load all saved guide books
  Future<void> _loadSavedGuideBooks() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final guidesDir = Directory('${directory.path}/guides');

      if (!await guidesDir.exists()) {
        debugPrint('ℹ️ GuideBookService: No saved guide books');
        return;
      }

      final files = await guidesDir
          .list()
          .where((entity) => entity.path.endsWith('.json'))
          .toList();

      for (var entity in files) {
        final file = File(entity.path);
        final jsonContent = await file.readAsString();
        final json = jsonDecode(jsonContent);
        final guideBook = GuideBook.fromJson(json);
        _guideBooks.add(guideBook);
      }

      debugPrint(
          '✅ GuideBookService: Loaded ${_guideBooks.length} guide books');

      // Load active guide book ID
      final activeId = await _loadActiveGuideBookId();
      if (activeId != null) {
        _activeGuideBook = _guideBooks.firstWhere(
          (gb) => gb.id == activeId,
          orElse: () => _guideBooks.isNotEmpty ? _guideBooks.first : null as GuideBook,
        );
      } else if (_guideBooks.isNotEmpty) {
        _activeGuideBook = _guideBooks.first;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ GuideBookService: Failed to load guide books: $e');
    }
  }

  /// Save active guide book ID
  Future<void> _saveActiveGuideBookId(String id) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/active_guide_book.txt');
    await file.writeAsString(id);
  }

  /// Load active guide book ID
  Future<String?> _loadActiveGuideBookId() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/active_guide_book.txt');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('⚠️ GuideBookService: Failed to load active guide book ID: $e');
    }
    return null;
  }
}
