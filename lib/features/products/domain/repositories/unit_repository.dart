// lib/features/products/domain/repositories/unit_repository.dart

import 'package:pos_app/features/products/domain/entities/birim_model.dart';
import 'package:pos_app/features/products/domain/entities/barkod_model.dart';

/// Birim ve Barkod verilerine erişim için repository interface
abstract class UnitRepository {
  /// Sunucudan tüm birimleri ve barkodları çeker ve veritabanına kaydeder
  /// Returns: başarı durumu
  Future<bool> fetchAndStoreBirimler();

  /// Belirli bir tarihten sonra güncellenen birimleri çeker
  /// [lastUpdateTime]: Son güncelleme zamanı
  Future<bool> fetchAndUpdateBirimler(DateTime lastUpdateTime);

  /// Veritabanından tüm birimleri getirir
  Future<List<BirimModel>> getAllBirimler();

  /// Belirli bir ürüne ait birimleri getirir
  /// [stokKodu]: Ürün stok kodu
  Future<List<BirimModel>> getBirimlerByStokKodu(String stokKodu);

  /// Belirli bir birim key'ine göre birim getirir
  /// [birimKey]: Birim _key değeri
  Future<BirimModel?> getBirimByKey(String birimKey);

  /// Belirli bir ürünün ERP key'ine göre birimleri getirir
  /// [productKey]: Ürün _key değeri (ERP'deki stok kartı key)
  Future<List<BirimModel>> getBirimlerByProductKey(String productKey);

  /// Veritabanından tüm barkodları getirir
  Future<List<BarkodModel>> getAllBarkodlar();

  /// Belirli bir birime ait barkodları getirir
  /// [birimKey]: Birim _key değeri
  Future<List<BarkodModel>> getBarkodlarByBirimKey(String birimKey);

  /// Barkod numarasına göre barkod bilgisini getirir
  /// [barkod]: Barkod numarası
  Future<BarkodModel?> getBarkodByNumber(String barkod);

  /// Veritabanındaki tüm birim verilerini siler
  Future<void> clearAllBirimler();

  /// Veritabanındaki tüm barkod verilerini siler
  Future<void> clearAllBarkodlar();

  /// Birim verilerini batch insert yapar (performans için)
  /// [birimler]: Kaydedilecek birimler listesi
  Future<void> insertBirimlerBatch(List<BirimModel> birimler);

  /// Barkod verilerini batch insert yapar (performans için)
  /// [barkodlar]: Kaydedilecek barkodlar listesi
  Future<void> insertBarkodlarBatch(List<BarkodModel> barkodlar);
}