class CustomerBalanceModel {
  final String? unvan;
  final String? vergiNo;
  final String? vergiDairesi;
  final String? adres;
  final String? telefon;
  final String? email;
  final String? kod;
  final String? postcode;
  final String? city;
  final String? contact;
  final String? mobile;
  final String? bakiye;

  CustomerBalanceModel({
    this.unvan,
    this.vergiNo,
    this.vergiDairesi,
    this.adres,
    this.telefon,
    this.email,
    this.kod,
    this.postcode,
    this.city,
    this.contact,
    this.mobile,
    this.bakiye,
  });

  factory CustomerBalanceModel.fromJson(Map<String, dynamic> json) {
    return CustomerBalanceModel(
      unvan: json['Unvan'],
      vergiNo: json['VergiNo'],
      vergiDairesi: json['VergiDairesi'],
      adres: json['Adres'],
      telefon: json['Telefon'],
      email: json['Email'],
      kod: json['Kod'],
      postcode: json['postcode'],
      city: json['City'],
      contact: json['Contact'],
      mobile: json['Mobile'],
      bakiye: json['bakiye']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'unvan': unvan,
      'vergiNo': vergiNo,
      'vergiDairesi': vergiDairesi,
      'adres': adres,
      'telefon': telefon,
      'email': email,
      'kod': kod,
      'postcode': postcode,
      'city': city,
      'contact': contact,
      'mobile': mobile,
      'bakiye': bakiye,
    };
  }
}
