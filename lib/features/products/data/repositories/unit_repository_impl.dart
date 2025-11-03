// lib/features/products/data/repositories/unit_repository_impl.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:pos_app/core/local/database_helper.dart';
import 'package:pos_app/core/network/api_config.dart';
import 'package:pos_app/features/products/domain/entities/birim_model.dart';
import 'package:pos_app/features/products/domain/entities/barkod_model.dart';
import 'package:pos_app/features/products/domain/repositories/unit_repository.dart';

class UnitRepositoryImpl implements UnitRepository {
  final DatabaseHelper _dbHelper;
  final Dio _dio;

  UnitRepositoryImpl({
    DatabaseHelper? dbHelper,
    Dio? dio,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _dio = dio ?? ApiConfig.dio;

  @override
  Future<bool> fetchAndStoreBirimler() async {
    try {
      debugPrint('🔄 Fetching all birimler and barkodlar from server...');

      // STEP 1: Get total counts first
      final countsResponse = await _dio.get(ApiConfig.birimCountsUrl);

      if (countsResponse.statusCode != 200 || countsResponse.data['status'] != 1) {
        debugPrint('❌ Failed to fetch counts');
        return false;
      }

      final birimlerCount = countsResponse.data['birimler_count'] as int;
      final barkodlarCount = countsResponse.data['barkodlar_count'] as int;

      debugPrint('📊 Total records: $birimlerCount birimler, $barkodlarCount barkodlar');

      // STEP 2: Download data page by page
      const pageSize = 5000;
      int page = 1;
      final allBirimler = <BirimModel>[];
      final allBarkodlar = <BarkodModel>[];

      while (true) {
        debugPrint('📥 Downloading page $page...');

        final response = await _dio.get(
          ApiConfig.birimlerListesiUrl,
          queryParameters: {'page': page, 'limit': pageSize},
        );

        if (response.statusCode == 200) {
          final data = response.data;

          if (data['status'] == 1) {
            final birimlerData = data['birimler'] as List<dynamic>? ?? [];
            final barkodlarData = data['barkodlar'] as List<dynamic>? ?? [];

            // Break if no more data
            if (birimlerData.isEmpty && barkodlarData.isEmpty) {
              debugPrint('✅ All pages downloaded');
              break;
            }

            // Parse and add to collections
            final birimler = birimlerData
                .map((json) => BirimModel.fromJson(json as Map<String, dynamic>))
                .toList();

            final barkodlar = barkodlarData
                .map((json) => BarkodModel.fromJson(json as Map<String, dynamic>))
                .toList();

            allBirimler.addAll(birimler);
            allBarkodlar.addAll(barkodlar);

            debugPrint('📥 Page $page: ${birimler.length} birimler, ${barkodlar.length} barkodlar (Total: ${allBirimler.length}/${birimlerCount} birimler, ${allBarkodlar.length}/${barkodlarCount} barkodlar)');

            page++;
          } else {
            debugPrint('❌ API returned status != 1 on page $page');
            return false;
          }
        } else {
          debugPrint('❌ Failed to fetch page $page: ${response.statusCode}');
          return false;
        }
      }

      // STEP 3: Batch insert all data
      debugPrint('💾 Storing all data in database...');
      await insertBirimlerBatch(allBirimler);
      await insertBarkodlarBatch(allBarkodlar);

      debugPrint('✅ Successfully stored ${allBirimler.length} birimler and ${allBarkodlar.length} barkodlar in database');
      return true;

    } catch (e) {
      debugPrint('❌ Error fetching birimler: $e');
      return false;
    }
  }

  @override
  Future<bool> fetchAndUpdateBirimler(DateTime lastUpdateTime) async {
    try {
      // Format: "01.05.2024 15:55:30"
      final formattedDate = DateFormat('dd.MM.yyyy HH:mm:ss').format(lastUpdateTime);
      debugPrint('🔄 Fetching updated birimler since: $formattedDate');

      final response = await _dio.get(
        ApiConfig.getNewBirimlerUrl,
        queryParameters: {'time': formattedDate},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['status'] == 1) {
          final birimlerData = data['birimler'] as List<dynamic>? ?? [];
          final barkodlarData = data['barkodlar'] as List<dynamic>? ?? [];

          debugPrint('✅ Received ${birimlerData.length} updated birimler and ${barkodlarData.length} barkodlar');

          if (birimlerData.isEmpty && barkodlarData.isEmpty) {
            debugPrint('ℹ️ No updates found');
            return true;
          }

          // Birimleri parse et
          final birimler = birimlerData
              .map((json) => BirimModel.fromJson(json as Map<String, dynamic>))
              .toList();

          // Barkodları parse et
          final barkodlar = barkodlarData
              .map((json) => BarkodModel.fromJson(json as Map<String, dynamic>))
              .toList();

          // Update or insert
          await _updateOrInsertBirimler(birimler);
          await _updateOrInsertBarkodlar(barkodlar);

          debugPrint('✅ Successfully updated birimler and barkodlar in database');
          return true;
        } else {
          debugPrint('❌ API returned status != 1');
          return false;
        }
      } else {
        debugPrint('❌ Failed to fetch updated birimler: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error fetching updated birimler: $e');
      return false;
    }
  }

  Future<void> _updateOrInsertBirimler(List<BirimModel> birimler) async {
    final db = await _dbHelper.database;

    for (final birim in birimler) {
      final existing = await db.query(
        'Birimler',
        where: '_key = ?',
        whereArgs: [birim.key],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        // Update
        await db.update(
          'Birimler',
          birim.toMap(),
          where: '_key = ?',
          whereArgs: [birim.key],
        );
      } else {
        // Insert
        await db.insert('Birimler', birim.toMap());
      }
    }
  }

  Future<void> _updateOrInsertBarkodlar(List<BarkodModel> barkodlar) async {
    final db = await _dbHelper.database;

    for (final barkod in barkodlar) {
      final existing = await db.query(
        'Barkodlar',
        where: '_key = ?',
        whereArgs: [barkod.key],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        // Update
        await db.update(
          'Barkodlar',
          barkod.toMap(),
          where: '_key = ?',
          whereArgs: [barkod.key],
        );
      } else {
        // Insert
        await db.insert('Barkodlar', barkod.toMap());
      }
    }
  }

  @override
  Future<List<BirimModel>> getAllBirimler() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('Birimler');
    return List.generate(maps.length, (i) => BirimModel.fromMap(maps[i]));
  }

  @override
  Future<List<BirimModel>> getBirimlerByStokKodu(String stokKodu) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Birimler',
      where: 'StokKodu = ?',
      whereArgs: [stokKodu],
    );
    return List.generate(maps.length, (i) => BirimModel.fromMap(maps[i]));
  }

  @override
  Future<BirimModel?> getBirimByKey(String birimKey) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Birimler',
      where: '_key = ?',
      whereArgs: [birimKey],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return BirimModel.fromMap(maps.first);
  }

  @override
  Future<List<BirimModel>> getBirimlerByProductKey(String productKey) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Birimler',
      where: '_key_scf_stokkart = ?',
      whereArgs: [productKey],
    );
    return List.generate(maps.length, (i) => BirimModel.fromMap(maps[i]));
  }

  @override
  Future<List<BarkodModel>> getAllBarkodlar() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('Barkodlar');
    return List.generate(maps.length, (i) => BarkodModel.fromMap(maps[i]));
  }

  @override
  Future<List<BarkodModel>> getBarkodlarByBirimKey(String birimKey) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Barkodlar',
      where: '_key_scf_stokkart_birimleri = ?',
      whereArgs: [birimKey],
    );
    return List.generate(maps.length, (i) => BarkodModel.fromMap(maps[i]));
  }

  @override
  Future<BarkodModel?> getBarkodByNumber(String barkod) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Barkodlar',
      where: 'barkod = ?',
      whereArgs: [barkod],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return BarkodModel.fromMap(maps.first);
  }

  @override
  Future<void> clearAllBirimler() async {
    final db = await _dbHelper.database;
    await db.delete('Birimler');
    debugPrint('🗑️ Cleared all birimler from database');
  }

  @override
  Future<void> clearAllBarkodlar() async {
    final db = await _dbHelper.database;
    await db.delete('Barkodlar');
    debugPrint('🗑️ Cleared all barkodlar from database');
  }

  @override
  Future<void> insertBirimlerBatch(List<BirimModel> birimler) async {
    if (birimler.isEmpty) return;

    final db = await _dbHelper.database;
    const batchSize = 1000; // Her batch'te 1000 kayıt
    int totalInserted = 0;

    // Batch'leri 1000'lik parçalara böl (SQLite deadlock önleme)
    for (int i = 0; i < birimler.length; i += batchSize) {
      final batch = db.batch();
      final end = (i + batchSize < birimler.length)
                  ? i + batchSize
                  : birimler.length;

      for (int j = i; j < end; j++) {
        batch.insert(
          'Birimler',
          birimler[j].toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      totalInserted += (end - i);

      // Her 5000 kayıtta bir ilerleme göster
      if (totalInserted % 5000 == 0 || totalInserted == birimler.length) {
        debugPrint('📦 Birimler: $totalInserted/${birimler.length} eklendi...');
      }
    }

    debugPrint('✅ Batch inserted ${birimler.length} birimler');
  }

  @override
  Future<void> insertBarkodlarBatch(List<BarkodModel> barkodlar) async {
    if (barkodlar.isEmpty) return;

    final db = await _dbHelper.database;
    const batchSize = 1000; // Her batch'te 1000 kayıt
    int totalInserted = 0;

    // Batch'leri 1000'lik parçalara böl (SQLite deadlock önleme)
    for (int i = 0; i < barkodlar.length; i += batchSize) {
      final batch = db.batch();
      final end = (i + batchSize < barkodlar.length)
                  ? i + batchSize
                  : barkodlar.length;

      for (int j = i; j < end; j++) {
        batch.insert(
          'Barkodlar',
          barkodlar[j].toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      totalInserted += (end - i);

      // Her 5000 kayıtta bir ilerleme göster
      if (totalInserted % 5000 == 0 || totalInserted == barkodlar.length) {
        debugPrint('📦 Barkodlar: $totalInserted/${barkodlar.length} eklendi...');
      }
    }

    debugPrint('✅ Batch inserted ${barkodlar.length} barkodlar');
  }
}