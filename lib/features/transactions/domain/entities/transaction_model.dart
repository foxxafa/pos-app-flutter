class TahsilatModel {
  final String fisno; // boş geçilecek
  final double tutar;
  final String aciklama;
  final String carikod; // müşteri carikodu
  final String username; // müşteri carikodu

  TahsilatModel({
    this.fisno = "",
    required this.tutar,
    required this.aciklama,
    required this.carikod,    required this.username,

  });

  Map<String, dynamic> toJson() => {
        "fisno": fisno,
        "tutar": tutar,
        "aciklama": aciklama,
        "carikod": carikod,
        "username":username
      };
}
