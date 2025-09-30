// providers/customer_provider.dart
import 'package:flutter/material.dart';
import 'package:pos_app/features/customer/domain/entities/customer_model.dart';

class SalesCustomerProvider extends ChangeNotifier {
  CustomerModel? _selectedCustomer;

  CustomerModel? get selectedCustomer => _selectedCustomer;

  void setCustomer(CustomerModel customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void clearCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }
}