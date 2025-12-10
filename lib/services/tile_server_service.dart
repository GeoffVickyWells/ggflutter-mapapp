import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:sqflite/sqflite.dart';

/// Local HTTP server for serving offline map tiles from MBTiles databases
class TileServerService {
  HttpServer? _server;
  int? _port;
  String? _baseUrl;
  final Map<String, Database> _databases = {}; // Cache MBTiles databases

  String? get baseUrl => _baseUrl;
  bool get isRunning => _server != null;

  /// Start the local tile server
  Future<void> start() async {
    if (_server != null) {
      debugPrint('⚠️ TileServerService: Server already running');
      return;
    }

    try {
      // Create handler for tile requests
      final handler = const shelf.Pipeline()
          .addMiddleware(shelf.logRequests())
          .addHandler(_handleRequest);

      // Start server on localhost with dynamic port
      _server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
      _port = _server!.port;
      _baseUrl = 'http://127.0.0.1:$_port';

      debugPrint('✅ TileServerService: Server started on $_baseUrl');
    } catch (e) {
      debugPrint('❌ TileServerService: Failed to start server: $e');
    }
  }

  /// Stop the local tile server
  Future<void> stop() async {
    if (_server == null) return;

    // Close all cached MBTiles databases
    for (final db in _databases.values) {
      await db.close();
    }
    _databases.clear();

    await _server!.close(force: true);
    _server = null;
    _port = null;
    _baseUrl = null;

    debugPrint('🛑 TileServerService: Server stopped');
  }

  /// Handle tile and font requests
  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    try {
      debugPrint('🌐 TileServerService: Request received: ${request.url.path}');

      final segments = request.url.pathSegments;

      // Handle font requests: /fonts/{fontstack}/{range}.pbf
      if (segments.isNotEmpty && segments[0] == 'fonts') {
        return await _handleFontRequest(segments);
      }

      // Handle tile requests: /tiles/{mapId}/{z}/{x}/{y}.pbf
      if (segments.length != 5 || segments[0] != 'tiles') {
        debugPrint('⚠️ TileServerService: Invalid path format');
        return shelf.Response.notFound('Invalid path');
      }

      final mapId = segments[1];
      final z = int.parse(segments[2]);
      final x = int.parse(segments[3]);
      final tileFile = segments[4];
      final y = int.parse(tileFile.replaceAll('.pbf', '').replaceAll('.png', ''));

      // Get or open MBTiles database
      if (!_databases.containsKey(mapId)) {
        await _openMBTilesDatabase(mapId);
      }

      final db = _databases[mapId];
      if (db == null) {
        debugPrint('❌ TileServerService: Database not found for $mapId');
        return shelf.Response.notFound('Database not found');
      }

      // Get tile data from MBTiles database
      try {
        // MBTiles uses TMS (Tile Map Service) addressing: y is flipped
        // Convert from XYZ (used by MapLibre) to TMS
        final tmsY = (1 << z) - 1 - y;

        debugPrint('🔢 TileServerService: Converting XYZ($z,$x,$y) to TMS($z,$x,$tmsY)');

        // Query the tile from the database
        final result = await db.query(
          'tiles',
          columns: ['tile_data'],
          where: 'zoom_level = ? AND tile_column = ? AND tile_row = ?',
          whereArgs: [z, x, tmsY],
        );

        if (result.isEmpty) {
          debugPrint('❌ TileServerService: Tile NOT FOUND: $mapId/$z/$x/$y (TMS: $tmsY)');
          return shelf.Response.notFound('Tile not found');
        }

        final tileData = result.first['tile_data'] as Uint8List;

        debugPrint('✅ TileServerService: Serving tile $mapId/$z/$x/$y (${tileData.length} bytes)');

        return shelf.Response.ok(
          tileData,
          headers: {
            'Content-Type': 'application/x-protobuf',
            'Content-Encoding': 'gzip',
            'Cache-Control': 'public, max-age=31536000',
            'Access-Control-Allow-Origin': '*',
          },
        );
      } catch (e) {
        debugPrint('❌ TileServerService: Error reading tile $mapId/$z/$x/$y: $e');
        return shelf.Response.notFound('Tile not found');
      }
    } catch (e) {
      debugPrint('❌ TileServerService: Error serving tile: $e');
      return shelf.Response.internalServerError(body: 'Error serving tile: $e');
    }
  }

  /// Open an MBTiles database from assets
  Future<void> _openMBTilesDatabase(String mapId) async {
    try {
      final assetPath = 'assets/maps/$mapId.mbtiles';
      debugPrint('📂 TileServerService: Loading MBTiles from $assetPath');

      // Load MBTiles file from assets
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      debugPrint('📦 TileServerService: Loaded ${bytes.length} bytes');

      // Write to a temporary file (sqflite needs a file path)
      final appDir = await getApplicationDocumentsDirectory();
      final tempPath = '${appDir.path}/$mapId.mbtiles';
      final file = File(tempPath);
      await file.writeAsBytes(bytes);

      debugPrint('💾 TileServerService: Wrote MBTiles to $tempPath');

      // Open the database
      final db = await openDatabase(
        tempPath,
        readOnly: true,
      );

      _databases[mapId] = db;

      // Log metadata
      final metadata = await db.query('metadata');
      debugPrint('✅ TileServerService: MBTiles opened for $mapId');
      debugPrint('📊 Metadata: $metadata');
    } catch (e) {
      debugPrint('❌ TileServerService: Failed to open MBTiles $mapId: $e');
      rethrow;
    }
  }

  /// Handle font glyph requests
  Future<shelf.Response> _handleFontRequest(List<String> segments) async {
    try {
      // Expected format: /fonts/{fontstack}/{range}.pbf
      if (segments.length != 3) {
        debugPrint('⚠️ TileServerService: Invalid font path format');
        return shelf.Response.notFound('Invalid font path');
      }

      final fontstack = Uri.decodeComponent(segments[1]);
      final rangeFile = segments[2]; // e.g., "0-255.pbf"

      // Load font glyph from assets
      final assetPath = 'assets/fonts/$fontstack/$rangeFile';
      debugPrint('📝 TileServerService: Loading font from $assetPath');

      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      debugPrint('✅ TileServerService: Serving font $fontstack/$rangeFile (${bytes.length} bytes)');

      return shelf.Response.ok(
        bytes,
        headers: {
          'Content-Type': 'application/x-protobuf',
          'Cache-Control': 'public, max-age=31536000',
          'Access-Control-Allow-Origin': '*',
        },
      );
    } catch (e) {
      debugPrint('❌ TileServerService: Error serving font: $e');
      return shelf.Response.notFound('Font not found');
    }
  }

  /// Get tile URL template for MapLibre style JSON
  String getTileUrlTemplate(String mapId, {bool isVector = false}) {
    if (_baseUrl == null) {
      throw StateError('Tile server not running');
    }
    final extension = isVector ? 'pbf' : 'png';
    return '$_baseUrl/tiles/$mapId/{z}/{x}/{y}.$extension';
  }

  /// Get font glyphs URL template for MapLibre style JSON
  String getFontGlyphsUrl() {
    if (_baseUrl == null) {
      throw StateError('Tile server not running');
    }
    return '$_baseUrl/fonts/{fontstack}/{range}.pbf';
  }
}
