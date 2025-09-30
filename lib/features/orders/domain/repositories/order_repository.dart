// lib/features/orders/domain/repositories/order_repository.dart
import 'package:pos_app/features/orders/domain/entities/order_model.dart';

abstract class OrderRepository {
  /// Create new order from cart
  Future<FisModel> createOrder(
    String musteriId,
    double toplamtutar,
    String odemeTuru,
    double nakitOdeme,
    double kartOdeme,
    List<Map<String, dynamic>> orderItems, {
    String deliveryDate = '',
    String comment = '',
  });

  /// Get all orders
  Future<List<FisModel>> getAllOrders();

  /// Get order by ID
  Future<FisModel?> getOrderById(String fisNo);

  /// Get orders by customer ID
  Future<List<FisModel>> getOrdersByCustomer(String musteriId);

  /// Get orders by date range
  Future<List<FisModel>> getOrdersByDateRange(DateTime startDate, DateTime endDate);

  /// Get orders by status
  Future<List<FisModel>> getOrdersByStatus(String status);

  /// Update order status
  Future<void> updateOrderStatus(String fisNo, String newStatus);

  /// Update order delivery date
  Future<void> updateOrderDeliveryDate(String fisNo, String deliveryDate);

  /// Add comment to order
  Future<void> updateOrderComment(String fisNo, String comment);

  /// Delete order
  Future<void> deleteOrder(String fisNo);

  /// Get order items
  Future<List<Map<String, dynamic>>> getOrderItems(String fisNo);

  /// Add item to order
  Future<void> addOrderItem(String fisNo, Map<String, dynamic> orderItem);

  /// Update order item
  Future<void> updateOrderItem(String fisNo, String stokKodu, Map<String, dynamic> updates);

  /// Remove item from order
  Future<void> removeOrderItem(String fisNo, String stokKodu);

  /// Get order total
  Future<double> calculateOrderTotal(String fisNo);

  /// Sync orders with server
  Future<void> syncOrders();

  /// Upload pending orders to server
  Future<void> uploadPendingOrders();

  /// Mark order as synced
  Future<void> markOrderAsSynced(String fisNo);

  /// Get pending orders (not synced)
  Future<List<FisModel>> getPendingOrders();

  /// Get orders count
  Future<int> getOrdersCount();

  /// Get today's orders
  Future<List<FisModel>> getTodaysOrders();

  /// Get orders summary (total amount, count, etc.)
  Future<Map<String, dynamic>> getOrdersSummary(DateTime date);

  /// Search orders by customer name or order number
  Future<List<FisModel>> searchOrders(String query);

  /// Get order payment details
  Future<Map<String, dynamic>> getOrderPaymentDetails(String fisNo);

  /// Update order payment
  Future<void> updateOrderPayment(String fisNo, double nakitOdeme, double kartOdeme, String odemeTuru);

  /// Cancel order
  Future<void> cancelOrder(String fisNo);

  /// Restore cancelled order
  Future<void> restoreOrder(String fisNo);

  /// Get order history for a specific order
  Future<List<Map<String, dynamic>>> getOrderHistory(String fisNo);

  /// Generate order receipt data
  Future<Map<String, dynamic>> generateOrderReceipt(String fisNo);

  // ============= Order Submission (for OrderController) =============

  /// Submit order to server (satisGonder)
  Future<bool> submitOrder({
    required FisModel fisModel,
    required List<dynamic> orderItems, // CartItem list
    required String bearerToken,
  });
}