import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Service de compression des données
class CompressionService {
  static final CompressionService _instance = CompressionService._();
  factory CompressionService() => _instance;
  CompressionService._();

  int _totalOriginalSize = 0;
  int _totalCompressedSize = 0;
  int _compressionOperations = 0;

  /// Compresse les données JSON
  List<int> compress(Map<String, dynamic> data) {
    try {
      final json = jsonEncode(data);
      final bytes = utf8.encode(json);
      final compressed = gzip.encode(bytes);

      _totalOriginalSize += bytes.length;
      _totalCompressedSize += compressed.length;
      _compressionOperations++;

      return compressed;
    } catch (e) {
      debugPrint('❌ Erreur compression: $e');
      rethrow;
    }
  }

  /// Décompresse les données
  Map<String, dynamic> decompress(List<int> compressedData) {
    try {
      final bytes = gzip.decode(compressedData);
      final json = utf8.decode(bytes);
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Erreur décompression: $e');
      rethrow;
    }
  }

  /// Calcule le ratio de compression
  double getCompressionRatio(Map<String, dynamic> data) {
    try {
      final originalSize = utf8.encode(jsonEncode(data)).length;
      final compressedSize = compress(data).length;
      return (1 - compressedSize / originalSize) * 100;
    } catch (e) {
      return 0;
    }
  }

  /// Compresse une liste de données
  List<int> compressList(List<Map<String, dynamic>> dataList) {
    try {
      final json = jsonEncode(dataList);
      final bytes = utf8.encode(json);
      final compressed = gzip.encode(bytes);

      _totalOriginalSize += bytes.length;
      _totalCompressedSize += compressed.length;
      _compressionOperations++;

      return compressed;
    } catch (e) {
      debugPrint('❌ Erreur compression liste: $e');
      rethrow;
    }
  }

  /// Décompresse une liste de données
  List<Map<String, dynamic>> decompressList(List<int> compressedData) {
    try {
      final bytes = gzip.decode(compressedData);
      final json = utf8.decode(bytes);
      final decoded = jsonDecode(json);
      return List<Map<String, dynamic>>.from(decoded as List);
    } catch (e) {
      debugPrint('❌ Erreur décompression liste: $e');
      rethrow;
    }
  }

  /// Obtient les statistiques de compression
  Map<String, dynamic> getCompressionStats() {
    final ratio = _totalOriginalSize > 0 ? (1 - _totalCompressedSize / _totalOriginalSize) * 100 : 0.0;

    return {
      'totalOperations': _compressionOperations,
      'totalOriginalSize': _totalOriginalSize,
      'totalCompressedSize': _totalCompressedSize,
      'savedBytes': _totalOriginalSize - _totalCompressedSize,
      'compressionRatio': ratio.toStringAsFixed(2),
    };
  }

  /// Format humain de la taille
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void resetStats() {
    _totalOriginalSize = 0;
    _totalCompressedSize = 0;
    _compressionOperations = 0;
    debugPrint('🔄 Statistiques de compression réinitialisées');
  }
}
