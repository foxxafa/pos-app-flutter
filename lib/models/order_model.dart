class FisModel {
  String fisNo;
  String fistarihi;
  String musteriId;
  double toplamtutar;
  String odemeTuru;
  double nakitOdeme;
  double kartOdeme;
  String status;
  String deliveryDate; // Yeni eklendi
  String comment;      // Yeni eklendi

  FisModel({
    required this.fisNo,
    required this.fistarihi,
    required this.musteriId,
    required this.toplamtutar,
    required this.odemeTuru,
    required this.nakitOdeme,
    required this.kartOdeme,
    required this.status,
    required this.deliveryDate,
    required this.comment,
  });

  Map<String, dynamic> toJson() => {
        "FisNo": fisNo,
        "Fistarihi": fistarihi,
        "MusteriId": musteriId,
        "Toplamtutar": toplamtutar,
        "OdemeTuru": odemeTuru,
        "NakitOdeme": nakitOdeme,
        "KartOdeme": kartOdeme,
        "Status": status,
        "DeliveryDate": deliveryDate,
        "Comment": comment,
      };
}
extension FisModelFormatter on FisModel {
  String toFormattedString() {
    return '''
Fiş No         : $fisNo
Fiş Tarihi     : $fistarihi
Müşteri ID     : $musteriId
Toplam Tutar   : $toplamtutar
Ödeme Türü     : $odemeTuru
Nakit          : $nakitOdeme
Kart           : $kartOdeme
Durum          : $status
Teslim Tarihi  : $deliveryDate
Yorum          : $comment
''';
  }
}
