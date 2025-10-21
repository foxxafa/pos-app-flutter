// providers/customer_provider.dart
import 'package:flutter/material.dart';
import 'package:pos_app/features/customer/domain/entities/customer_model.dart';
import 'package:pos_app/features/cart/presentation/providers/cart_provider.dart';

class SalesCustomerProvider extends ChangeNotifier {
  CustomerModel? _selectedCustomer;
  CartProvider? _cartProvider;

  CustomerModel? get selectedCustomer => _selectedCustomer;

  /// Link CartProvider so we can auto-set customer info when customer is selected
  void linkCartProvider(CartProvider cartProvider) {
    _cartProvider = cartProvider;
  }

  void setCustomer(CustomerModel customer) {
    _selectedCustomer = customer;

    // ✅ KRITIK: Customer seçildiğinde CartProvider'a da customerKod ve customerName set et
    if (_cartProvider != null && customer.kod != null) {
      _cartProvider!.customerKod = customer.kod!;
      _cartProvider!.customerName = customer.unvan ?? customer.kod!;
      print("✅ Customer selected: kod='${customer.kod}', name='${customer.unvan}'");
      print("✅ CartProvider updated: customerKod='${_cartProvider!.customerKod}', customerName='${_cartProvider!.customerName}'");
    }

    notifyListeners();
  }

  void clearCustomer() {
    _selectedCustomer = null;

    // ✅ Customer temizlendiğinde CartProvider'ı da temizle
    if (_cartProvider != null) {
      _cartProvider!.customerKod = '';
      _cartProvider!.customerName = '';
      print("✅ Customer cleared, CartProvider customer info also cleared");
    }

    notifyListeners();
  }
}