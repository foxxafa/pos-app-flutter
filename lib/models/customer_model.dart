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
      kod: map['Kod'] ?? '',
      unvan: map['Unvan'] ?? '',
      telefon: map['Telefon'] ?? '',
      adres: map['Adres'] ?? '',
      aktif: (map['Aktif'] ?? 0), // SQLite için 1 = true
    );
  }
}
