// lib/features/products/domain/entities/barkod_model.dart

/// Ürün barkodu
/// Backend'deki `barkodlar` tablosunu temsil eder
class BarkodModel {
  final int? id;
  final String? key;                      // DIA ERP'deki barkod key
  final String? keyBirim;                 // Birim ile ilişki (_key_scf_stokkart_birimleri)
  final String? barkod;                   // Barkod numarası
  final String? turu;                     // Barkod türü (EAN13, CODE128 vb.)
  final String? createdAt;
  final String? updatedAt;

  BarkodModel({
    this.id,
    this.key,
    this.keyBirim,
    this.barkod,
    this.turu,
    this.createdAt,
    this.updatedAt,
  });

  /// JSON'dan model oluştur (API response)
  factory BarkodModel.fromJson(Map<String, dynamic> json) {
    return BarkodModel(
      id: json['id'] as int?,
      key: json['_key'] as String?,
      keyBirim: json['_key_scf_stokkart_birimleri'] as String?,
      barkod: json['barkod'] as String?,
      turu: json['turu'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  /// Veritabanı map'inden model oluştur
  factory BarkodModel.fromMap(Map<String, dynamic> map) {
    return BarkodModel(
      id: map['id'] as int?,
      key: map['_key'] as String?,
      keyBirim: map['_key_scf_stokkart_birimleri'] as String?,
      barkod: map['barkod'] as String?,
      turu: map['turu'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// Veritabanına kaydetmek için map'e çevir
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      '_key': key,
      '_key_scf_stokkart_birimleri': keyBirim,
      'barkod': barkod,
      'turu': turu,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() {
    return 'BarkodModel(id: $id, barkod: $barkod, turu: $turu, keyBirim: $keyBirim)';
  }
}