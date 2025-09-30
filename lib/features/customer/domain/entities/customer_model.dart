class CustomerModel {
  final int? id; // Repository'de kullanılan ID field'i
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
    this.id,
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
      id: map['id'],
      kod: map['kod'] ?? map['Kod'] ?? '', // Hem eski hem yeni format desteği
      unvan: map['unvan'] ?? map['Unvan'] ?? '',
      telefon: map['telefon'] ?? map['Telefon'] ?? '',
      adres: map['adres'] ?? map['Adres'] ?? '',
      vergiNo: map['vergiNo'] ?? map['VergiNo'] ?? '',
      vergiDairesi: map['vergiDairesi'] ?? map['VergiDairesi'] ?? '',
      email: map['email'] ?? map['Email'] ?? '',
      postCode: map['postcode'] ?? map['PostCode'] ?? '',
      aktif: map['aktif'] ?? map['Aktif'] ?? 1,
    );
  }

  // copyWith method for repository usage
  CustomerModel copyWith({
    int? id,
    String? vergiNo,
    String? vergiDairesi,
    String? adres,
    String? telefon,
    String? email,
    String? kod,
    String? unvan,
    String? postCode,
    int? aktif,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      vergiNo: vergiNo ?? this.vergiNo,
      vergiDairesi: vergiDairesi ?? this.vergiDairesi,
      adres: adres ?? this.adres,
      telefon: telefon ?? this.telefon,
      email: email ?? this.email,
      kod: kod ?? this.kod,
      unvan: unvan ?? this.unvan,
      postCode: postCode ?? this.postCode,
      aktif: aktif ?? this.aktif,
    );
  }
}
