class RefundSendModel {
  final RefundFisModel fis;
  final List<RefundItemModel> satirlar;

  RefundSendModel({required this.fis, required this.satirlar});

  Map<String, dynamic> toJson() => {
        "fis": fis.toJson(),
        "satirlar": satirlar.map((e) => e.toJson()).toList(),
      };
}

class RefundFisModel {
  final String fisNo;
  final String fistarihi;
  final String musteriId;
  double toplamtutar;
  final String aciklama;
  final int status;
  final String iadeNedeni;

  RefundFisModel({
    required this.fisNo,
    required this.fistarihi,
    required this.musteriId,
    required this.toplamtutar,
    this.aciklama = '',
    this.status = 2,
    this.iadeNedeni = '',
  });

  Map<String, dynamic> toJson() => {
        "FisNo": fisNo,
        "Fistarihi": fistarihi,
        "MusteriId": musteriId,
        "Toplamtutar": toplamtutar,
        "aciklama": aciklama,
        "Status": status,
        "IadeNedeni": iadeNedeni,
      };
}

extension RefundFisFormatter on RefundFisModel {
  String toFormattedString() {
    return '''
No           : $fisNo
Date         : $fistarihi
Customer ID  : $musteriId
Total Amount : $toplamtutar
Description  : $aciklama
Return Reason: $iadeNedeni
Status       : $status
''';
  }
}


class RefundItemModel {
  final String stokKodu;
  final String urunAdi;
  final int miktar;
  final double birimFiyat;
  final double toplamTutar;
  final int vat;
  final String birimTipi;
  final String durum;
  final String urunBarcode;
  final double iskonto;
  final String aciklama; // ✅ Yeni alan

  RefundItemModel({
    required this.stokKodu,
    required this.urunAdi,
    required this.miktar,
    required this.birimFiyat,
    required this.toplamTutar,
    required this.vat,
    required this.birimTipi,
    required this.durum,
    required this.urunBarcode,
    required this.iskonto,
    required this.aciklama, // ✅ Constructor'a eklendi
  });

  Map<String, dynamic> toJson() => {
        "StokKodu": stokKodu,
        "UrunAdi": urunAdi,
        "Miktar": miktar,
        "BirimFiyat": birimFiyat,
        "ToplamTutar": toplamTutar,
        "vat": vat,
        "BirimTipi": birimTipi,
        "Durum": durum,
        "UrunBarcode": urunBarcode,
        "Iskonto": iskonto,
        "aciklama": aciklama, // ✅ JSON'a eklendi
      };
}


extension RefundItemFormatter on RefundItemModel {
  String toFormattedString() {
    return '''
Stock Code   : $stokKodu
Product Name : $urunAdi
Quantity     : $miktar
Unit Price   : $birimFiyat
Total Price  : $toplamTutar
VAT          : $vat
Unit Type    : $birimTipi
Status       : $durum
Barcode      : $urunBarcode
Discount     : $iskonto
Note         : $aciklama
''';
  }
}




extension RefundSendFormatter on RefundSendModel {
  String toFormattedString() {
    final satirlarText = satirlar
        .map((e) => e.toFormattedString())
        .join('\n----------------------\n');

    return '''
📄 Return Receipt
${fis.toFormattedString()}
🛒 Returns:
$satirlarText
''';
  }
}
