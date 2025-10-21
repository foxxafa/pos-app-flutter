import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderInfoProvider extends ChangeNotifier {
  String orderNo = '';
  String comment = '';
  String paymentType = 'Nakit';
  String paymentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());
  String deliveryDate = DateFormat('dd.MM.yyyy').format(DateTime.now());

  void setOrderInfo({
    required String orderNo,
    required String comment,
    required String paymentType,
    required String paymentDate,
    required String deliveryDate,
  }) {
    this.orderNo = orderNo;
    this.comment = comment;
    this.paymentType = paymentType;
    this.paymentDate = paymentDate;
    this.deliveryDate = deliveryDate;
    notifyListeners();
  }

  void clear() {
    orderNo = '';
    comment = '';
    paymentType = 'Nakit';
    paymentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());
    deliveryDate = DateFormat('dd.MM.yyyy').format(DateTime.now());
    notifyListeners();
  }

  /// Generate a new unique order number (fisNo)
  /// Format: MO + timestamp (last 8 digits of milliseconds since epoch)
  void generateNewOrderNo() {
    orderNo = 'MO${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    notifyListeners();
  }
}
