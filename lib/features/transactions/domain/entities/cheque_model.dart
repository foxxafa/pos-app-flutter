class ChequeModel {
  final String fisno; // boş geçilecek
  final double tutar;
  final String aciklama;
  final String carikod; // müşteri carikodu
  final String username; // müşteri carikodu
  final String cekno; // müşteri carikodu
  final String vade; // müşteri carikodu

ChequeModel({
  this.fisno = "",
  required this.tutar,
  required this.aciklama,
  required this.carikod,
  required this.username,
  this.cekno = "",
  this.vade = "",
});


  Map<String, dynamic> toJson() => {
        "fisno": fisno,
        "tutar": tutar,
        "aciklama": aciklama,
        "carikod": carikod,
        "username":username,
        "cekno": cekno,
"vade": vade,

      };
}
