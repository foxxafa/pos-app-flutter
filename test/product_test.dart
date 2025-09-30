import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/features/customer/presentation/customer_controller.dart';

void main() {
  test('getNewCustomer returns list and prints first two customers', () async {
    final controller = CustomerController();

    // Gerçek token ve tarih koy
    // final bearerToken = 'e5e8ca817118a95d4170a6375013180468606493d4b1fb9d0e73186209b8c84e';
    final date = DateTime(2025, 5, 1, 15, 55, 30);

    final customers = await controller.getNewCustomer(date);

    expect(customers, isNotNull);
    expect(customers!.length, greaterThanOrEqualTo(2));

    print('First customer: ${customers[0].unvan}');
    print('Second customer: ${customers[1].unvan}');
  });
}
