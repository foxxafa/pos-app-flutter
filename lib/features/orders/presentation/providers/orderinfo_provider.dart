import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_app/core/utils/fisno_generator.dart';
import 'package:pos_app/core/local/database_helper.dart';

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
  /// Format: MO + YY + MM + DD + UserID + Minute + Microsecond (16 characters)
  /// Example: MO25110201525683
  Future<void> generateNewOrderNo() async {
    try {
      // Get user ID from database
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      final result = await db.query('Login', limit: 1);
      final int userId = result.isNotEmpty ? (result.first['id'] as int) : 1;

      // Generate fisNo using FisNoGenerator (16 characters)
      orderNo = FisNoGenerator.generate(userId: userId);

      // Clear comment when generating new order number
      comment = '';

      print('✅ FisNo generated: $orderNo (UserID: $userId)');
      notifyListeners();
    } catch (e) {
      print('⚠️ Error generating fisNo: $e');
      // Fallback: Use timestamp-based generation
      orderNo = 'MO${DateTime.now().millisecondsSinceEpoch.toString().substring(3, 17)}';
      comment = '';
      notifyListeners();
    }
  }
}
