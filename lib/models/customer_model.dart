class CustomerModel {
  final String? vergiNo;
  final String? vergiDairesi;
  final String? adres;
  final String? telefon;
  final String? email;
  final String? kod;
  final String? unvan;
  final String? postCode;
  final int? aktif;

  CustomerModel({
    this.vergiNo,
    this.vergiDairesi,
    this.adres,
    this.telefon,
    this.email,
    this.kod,
    this.unvan,
    this.postCode,
    this.aktif,
  });

    Map<String, dynamic> toMap() {
    return {
      'VergiNo': vergiNo,
      'VergiDairesi': vergiDairesi,
      'Adres': adres,
      'Telefon': telefon,
      'Email': email,
      'Kod': kod,
      'Unvan': unvan,
      'PostCode': postCode,
      'Aktif': aktif,
    };
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      vergiNo: json['VergiNo'],
      vergiDairesi: json['VergiDairesi'],
      adres: json['Adres'],
      telefon: json['Telefon'],
      email: json['Email'],
      kod: json['Kod'],
      unvan: json['Unvan'],
      postCode: json['PostCode'],
      aktif: json['Aktif'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'VergiNo': vergiNo,
      'VergiDairesi': vergiDairesi,
      'Adres': adres,
      'Telefon': telefon,
      'Email': email,
      'Kod': kod,
      'Unvan': unvan,
      'PostCode': postCode,
      'Aktif': aktif,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      // CustomerBalance table columns (küçük harfler)
      kod: map['kod'] ?? map['Kod'] ?? '', // Hem eski hem yeni format desteği
      unvan: map['unvan'] ?? map['Unvan'] ?? '',
      telefon: map['telefon'] ?? map['Telefon'] ?? '',
      adres: map['adres'] ?? map['Adres'] ?? '',
      vergiNo: map['vergiNo'] ?? map['VergiNo'] ?? '',
      vergiDairesi: map['vergiDairesi'] ?? map['VergiDairesi'] ?? '',
      email: map['email'] ?? map['Email'] ?? '',
      postCode: map['postcode'] ?? map['PostCode'] ?? '',
      aktif: 1, // CustomerBalance'da aktif field yok, default 1
    );
  }
}
