import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/controllers/product_controller.dart';

void main() {
  test('getNewCustomer returns list and prints first two customers', () async {
    final controller = ProductController();

    // Gerçek token ve tarih koy
    // final bearerToken = 'e5264ab8f341b7771f44345700a4914c9af90527bc4a922965638ad08f9de0ae';
    final date = DateTime(2025, 1, 1, 1, 55, 30);

    final customers = await controller.getNewProduct(date);

    expect(customers, isNotNull);
    expect(customers!.length, greaterThanOrEqualTo(2));

    print('First customer: ${customers[0].urunAdi}');
    print('Second customer: ${customers[1].urunAdi}');
  });
}
