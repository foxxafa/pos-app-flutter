class Refund {
  final String fisNo;
  final String musteriId;
  final DateTime fisTarihi;
  final String unvan;
  final String stokKodu;
  final String urunAdi;
  final String urunBarcode;
  final double miktar;
  final String birim;
  final double birimFiyat;
  final int vat;
  final double iskonto;

  Refund({
    required this.fisNo,
    required this.musteriId,
    required this.fisTarihi,
    required this.unvan,
    required this.stokKodu,
    required this.urunAdi,
    required this.urunBarcode,
    required this.miktar,
    required this.birim,
    required this.birimFiyat,
  required this.vat,
  required this.iskonto,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      fisNo: json['FisNo'] ?? '',
      musteriId: json['MusteriId'] ?? '',
      fisTarihi: DateTime.parse(json['FisTarihi']),
      unvan: json['Unvan'] ?? '',
      stokKodu: json['StokKodu'] ?? '',
      urunAdi: json['UrunAdi'] ?? '',
      urunBarcode: json['UrunBarcode'] ?? '',
      miktar: double.tryParse(json['Miktar'] ?? '0') ?? 0,
      vat: int.tryParse(json['vat'] ?? '0') ?? 0,
      iskonto: double.tryParse(json['iskonto'] ?? '0') ?? 0.0,
      birim: json['Birim'] ?? '',
      birimFiyat: double.tryParse(json['BirimFiyat'] ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fisNo': fisNo,
      'musteriId': musteriId,
      'fisTarihi': fisTarihi.toIso8601String(),
      'unvan': unvan,
      'stokKodu': stokKodu,
      'urunAdi': urunAdi,
      'urunBarcode': urunBarcode,
      'miktar': miktar,
      'birim': birim,
      'vat': vat,
      'iskonto': iskonto,
      'birimFiyat': birimFiyat,
    };
  }

  factory Refund.fromMap(Map<String, dynamic> map) {
    return Refund(
      fisNo: map['fisNo'],
      musteriId: map['musteriId'],
      fisTarihi: DateTime.parse(map['fisTarihi']),
      unvan: map['unvan'],
      stokKodu: map['stokKodu'],
      urunAdi: map['urunAdi'],
      urunBarcode: map['urunBarcode'],
      miktar: map['miktar'],vat: map['vat'],iskonto: map['iskonto'],
      birim: map['birim'],
      birimFiyat: map['birimFiyat'],
    );
  }

}
String formatRefundList(List<Refund> refunds) {
  if (refunds.isEmpty) return "No refunds found.";

  final buffer = StringBuffer();

  for (final refund in refunds) {
    buffer.writeln("➤ Fis No: ${refund.fisNo}");
    buffer.writeln("  Tarih: ${refund.fisTarihi.toIso8601String().split('T').first}");
    buffer.writeln("  Müşteri: ${refund.unvan} (ID: ${refund.musteriId})");
    buffer.writeln("  Ürün: ${refund.urunAdi}");
    buffer.writeln("  Stok Kodu: ${refund.stokKodu}");
    buffer.writeln("  Barkod: ${refund.urunBarcode}");
    buffer.writeln("  Miktar: ${refund.miktar} ${refund.birim}");
    buffer.writeln("  Fiyat: ${refund.birimFiyat.toStringAsFixed(2)} ");
    buffer.writeln("  KDV: %${refund.vat}");
    buffer.writeln("  İskonto: %${refund.iskonto}");
    buffer.writeln("  ------------------------------");
  }

  return buffer.toString();
}