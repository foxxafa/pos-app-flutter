// lib/features/refunds/domain/repositories/refund_repository.dart
import 'package:pos_app/features/refunds/domain/entities/refundlist_model.dart';
import 'package:pos_app/features/refunds/domain/entities/refundsend_model.dart';

abstract class RefundRepository {
  // ============= Refund List Methods (from RefundListController) =============

  /// Fetch refunds from server by customer code
  Future<List<Refund>> fetchRefunds(String cariKod);

  /// Get refunds by customer ID from local database
  Future<List<Refund>> getRefundsByMusteriId(String musteriId);

  /// Get refunds by customer ID and stock code from local database
  Future<List<Refund>> getRefundsByMusteriIdAndStokKodu(String musteriId, String stokKodu);

  /// Insert pending refund to local database
  Future<void> insertPendingRefund(Map<String, dynamic> pendingData);

  // ============= Refund Send Methods (from RefundSendController) =============

  /// Send refund to server (online) or save to queue (offline)
  Future<bool> sendRefund(RefundSendModel refund);

  /// Save refund to offline queue
  Future<void> saveRefundOffline(RefundSendModel refund);

  /// Get all offline refunds from queue
  Future<List<Map<String, dynamic>>> getOfflineRefunds();

  /// Delete refund from queue by ID
  Future<void> deleteRefundById(int id);

  /// Send all pending offline refunds
  Future<void> sendPendingRefunds();
}