class ProductModel {
  final int? id;
  final String stokKodu;
  final String adetFiyati;
  final String kutuFiyati;
  final String pm1;
  final String pm2;
  final String pm3;
  final String barcode1;
  final String barcode2;
  final String barcode3;
  final String barcode4;
  final int vat;
  final String urunAdi;
  final String birim1;
  final int birimKey1;
  final String birim2;
  final int birimKey2;
  final int aktif;
  final String? imsrc; // Yeni alan

  ProductModel({
    this.id,
    required this.stokKodu,
    required this.adetFiyati,
    required this.kutuFiyati,
    required this.pm1,
    required this.pm2,
    required this.pm3,
    required this.barcode1,
    required this.barcode2,
    required this.barcode3,
    required this.barcode4,
    required this.vat,
    required this.urunAdi,
    required this.birim1,
    required this.birimKey1,
    required this.birim2,
    required this.birimKey2,
    required this.aktif,
    this.imsrc, // Yeni alan
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      stokKodu: json['StokKodu'] ?? '',
      adetFiyati: json['AdetFiyati'] ?? '0',
      kutuFiyati: json['KutuFiyati'] ?? '0',
      pm1: json['Pm1'] ?? '',
      pm2: json['Pm2'] ?? '',
      pm3: json['Pm3'] ?? '',
      barcode1: json['Barcode1'] ?? '',
      barcode2: json['Barcode2'] ?? '',
      barcode3: json['Barcode3'] ?? '',
      barcode4: json['Barcode4'] ?? '',
      vat: double.tryParse(json['Vat']?.toString() ?? '0')?.toInt() ?? 0,
      urunAdi: json['UrunAdi'] ?? '',
      birim1: json['Birim1'] ?? '',
      birimKey1: json['BirimKey1'] ?? 0,
      birim2: json['Birim2'] ?? '',
      birimKey2: json['BirimKey2'] is int ? json['BirimKey2'] : int.tryParse(json['BirimKey2']?.toString() ?? '0') ?? 0,
      aktif: json['Aktif'] ?? 0,
      imsrc: json['imsrc'], // Yeni alan
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'StokKodu': stokKodu,
      'AdetFiyati': adetFiyati,
      'KutuFiyati': kutuFiyati,
      'Pm1': pm1,
      'Pm2': pm2,
      'Pm3': pm3,
      'Barcode1': barcode1,
      'Barcode2': barcode2,
      'Barcode3': barcode3,
      'Barcode4': barcode4,
      'Vat': vat,
      'UrunAdi': urunAdi,
      'Birim1': birim1,
      'BirimKey1': birimKey1,
      'Birim2': birim2,
      'BirimKey2': birimKey2,
      'Aktif': aktif,
      'imsrc': imsrc, // Yeni alan
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stokKodu': stokKodu,
      'adetFiyati': adetFiyati,
      'kutuFiyati': kutuFiyati,
      'pm1': pm1,
      'pm2': pm2,
      'pm3': pm3,
      'barcode1': barcode1,
      'barcode2': barcode2,
      'barcode3': barcode3,
      'barcode4': barcode4,
      'vat': vat,
      'urunAdi': urunAdi,
      'birim1': birim1,
      'birimKey1': birimKey1,
      'birim2': birim2,
      'birimKey2': birimKey2,
      'aktif': aktif,
      'imsrc': imsrc, // Yeni alan
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] is int ? map['id'] : int.tryParse(map['id']?.toString() ?? '0'),
      stokKodu: map['stokKodu'] ?? '',
      urunAdi: map['urunAdi'] ?? '',
      adetFiyati: map['adetFiyati']?.toString() ?? '0',
      kutuFiyati: map['kutuFiyati']?.toString() ?? '0',
      barcode1: map['barcode1']?.toString() ?? '',
      barcode2: map['barcode2']?.toString() ?? '',
      barcode3: map['barcode3']?.toString() ?? '',
      barcode4: map['barcode4']?.toString() ?? '',
      aktif: map['aktif'] is int ? map['aktif'] : int.tryParse(map['aktif']?.toString() ?? '0') ?? 0,
      pm1: map['pm1']?.toString() ?? '',
      pm2: map['pm2']?.toString() ?? '',
      pm3: map['pm3']?.toString() ?? '',
      vat: map['vat'] is int ? map['vat'] : int.tryParse(map['vat']?.toString() ?? '0') ?? 0,
      birim1: map['birim1']?.toString() ?? '',
      birimKey1: map['birimKey1'] is int ? map['birimKey1'] : int.tryParse(map['birimKey1']?.toString() ?? '0') ?? 0,
      birim2: map['birim2']?.toString() ?? '',
      birimKey2: map['birimKey2'] is int ? map['birimKey2'] : int.tryParse(map['birimKey2']?.toString() ?? '0') ?? 0,
      imsrc: map['imsrc']?.toString(), // Yeni alan
    );
  }
}