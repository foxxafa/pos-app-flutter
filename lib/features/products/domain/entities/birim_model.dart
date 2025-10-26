// lib/features/products/domain/entities/birim_model.dart

/// Ürün birimi (UNIT, BOX, PALLET vb.)
/// Backend'deki `birimler` tablosunu temsil eder
class BirimModel {
  final int? id;
  final String? birimadi;        // "UNIT", "BOX", "PALLET"
  final String? birimkod;        // Birim kodu
  final double carpan;           // Çarpan (1 BOX = 4 UNIT ise carpan=4)
  final double? fiyat1;
  final double? fiyat2;
  final double? fiyat3;
  final double? fiyat4;
  final double? fiyat5;
  final double? fiyat6;
  final double? fiyat7;
  final double? fiyat8;
  final double? fiyat9;
  final double? fiyat10;
  final String? key;             // DIA ERP'deki birim key
  final String? keyStokkart;     // Ürün ile ilişki (_key_scf_stokkart)
  final String? stokKodu;        // Ürün stok kodu
  final String? createdAt;
  final String? updatedAt;

  BirimModel({
    this.id,
    this.birimadi,
    this.birimkod,
    this.carpan = 1.0,
    this.fiyat1,
    this.fiyat2,
    this.fiyat3,
    this.fiyat4,
    this.fiyat5,
    this.fiyat6,
    this.fiyat7,
    this.fiyat8,
    this.fiyat9,
    this.fiyat10,
    this.key,
    this.keyStokkart,
    this.stokKodu,
    this.createdAt,
    this.updatedAt,
  });

  /// JSON'dan model oluştur (API response)
  factory BirimModel.fromJson(Map<String, dynamic> json) {
    return BirimModel(
      id: json['id'] as int?,
      birimadi: json['birimadi'] as String?,
      birimkod: json['birimkod'] as String?,
      carpan: _parseDouble(json['carpan']) ?? 1.0,
      fiyat1: _parseDouble(json['fiyat1']),
      fiyat2: _parseDouble(json['fiyat2']),
      fiyat3: _parseDouble(json['fiyat3']),
      fiyat4: _parseDouble(json['fiyat4']),
      fiyat5: _parseDouble(json['fiyat5']),
      fiyat6: _parseDouble(json['fiyat6']),
      fiyat7: _parseDouble(json['fiyat7']),
      fiyat8: _parseDouble(json['fiyat8']),
      fiyat9: _parseDouble(json['fiyat9']),
      fiyat10: _parseDouble(json['fiyat10']),
      key: json['_key'] as String?,
      keyStokkart: json['_key_scf_stokkart'] as String?,
      stokKodu: json['StokKodu'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  /// Veritabanı map'inden model oluştur
  factory BirimModel.fromMap(Map<String, dynamic> map) {
    return BirimModel(
      id: map['id'] as int?,
      birimadi: map['birimadi'] as String?,
      birimkod: map['birimkod'] as String?,
      carpan: _parseDouble(map['carpan']) ?? 1.0,
      fiyat1: _parseDouble(map['fiyat1']),
      fiyat2: _parseDouble(map['fiyat2']),
      fiyat3: _parseDouble(map['fiyat3']),
      fiyat4: _parseDouble(map['fiyat4']),
      fiyat5: _parseDouble(map['fiyat5']),
      fiyat6: _parseDouble(map['fiyat6']),
      fiyat7: _parseDouble(map['fiyat7']),
      fiyat8: _parseDouble(map['fiyat8']),
      fiyat9: _parseDouble(map['fiyat9']),
      fiyat10: _parseDouble(map['fiyat10']),
      key: map['_key'] as String?,
      keyStokkart: map['_key_scf_stokkart'] as String?,
      stokKodu: map['StokKodu'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  /// Veritabanına kaydetmek için map'e çevir
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'birimadi': birimadi,
      'birimkod': birimkod,
      'carpan': carpan,
      'fiyat1': fiyat1,
      'fiyat2': fiyat2,
      'fiyat3': fiyat3,
      'fiyat4': fiyat4,
      'fiyat5': fiyat5,
      'fiyat6': fiyat6,
      'fiyat7': fiyat7,
      'fiyat8': fiyat8,
      'fiyat9': fiyat9,
      'fiyat10': fiyat10,
      '_key': key,
      '_key_scf_stokkart': keyStokkart,
      'StokKodu': stokKodu,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// String/dynamic'i double'a çevirme helper
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Stok miktarını bu birim için hesapla
  /// qty: UNIT bazında toplam stok
  /// Örnek: qty=200 UNIT, carpan=4 BOX → 50 BOX
  int calculateStockForUnit(double qty) {
    if (carpan <= 0) return 0;
    return (qty / carpan).floor(); // Sadece tam kısmı döndür
  }

  /// Birim adını gösterim için formatla
  String get displayName => birimadi ?? birimkod ?? 'Unknown';

  @override
  String toString() {
    return 'BirimModel(id: $id, birimadi: $birimadi, carpan: $carpan, stokKodu: $stokKodu)';
  }
}