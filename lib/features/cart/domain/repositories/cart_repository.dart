// lib/features/cart/domain/repositories/cart_repository.dart

abstract class CartRepository {
  /// Add item to cart
  Future<void> addItemToCart(String stokKodu, String urunAdi, double birimFiyat,
      String urunBarcode, int vat, {int miktar = 1, String birimTipi = 'Unit',
      int iskonto = 0, String? imsrc, String adetFiyati = '', String kutuFiyati = '',
      String aciklama = '', int birimKey1 = 0, int birimKey2 = 0});

  /// Remove item from cart
  Future<void> removeItemFromCart(String stokKodu);

  /// Update item quantity in cart
  Future<void> updateItemQuantity(String stokKodu, int newQuantity);

  /// Update item discount in cart
  Future<void> updateItemDiscount(String stokKodu, int discount);

  /// Update item price in cart
  Future<void> updateItemPrice(String stokKodu, double newPrice);

  /// Get all cart items
  Future<List<Map<String, dynamic>>> getCartItems();

  /// Get cart item by product code
  Future<Map<String, dynamic>?> getCartItemByCode(String stokKodu);

  /// Clear all cart items
  Future<void> clearCart();

  /// Get cart total (without VAT)
  Future<double> getCartSubtotal();

  /// Get cart total (with VAT and discounts)
  Future<double> getCartTotal();

  /// Get total VAT amount
  Future<double> getCartVATAmount();

  /// Get total discount amount
  Future<double> getCartDiscountAmount();

  /// Get cart items count
  Future<int> getCartItemsCount();

  /// Save cart with name (for later retrieval)
  Future<void> saveCart(String cartName, String? customerCode);

  /// Load saved cart by name
  Future<void> loadSavedCart(String cartName);

  /// Get all saved carts
  Future<List<Map<String, dynamic>>> getSavedCarts();

  /// Delete saved cart
  Future<void> deleteSavedCart(String cartName);

  /// Check if item exists in cart
  Future<bool> isItemInCart(String stokKodu);

  /// Get cart item quantity
  Future<int> getItemQuantity(String stokKodu);

  /// Merge cart with another cart
  Future<void> mergeCart(List<Map<String, dynamic>> otherCartItems);

  /// Get cart summary (items count, total amount, etc.)
  Future<Map<String, dynamic>> getCartSummary();

  /// Apply bulk discount to cart
  Future<void> applyBulkDiscount(double discountPercentage);

  /// Set customer for current cart
  Future<void> setCartCustomer(String? customerCode);

  /// Get current cart customer
  Future<String?> getCartCustomer();

  /// Validate cart before checkout
  Future<bool> validateCart();

  /// Get cart history
  Future<List<Map<String, dynamic>>> getCartHistory();

  // ============= Customer-based Cart Methods (for CartProvider) =============

  /// Clear cart items by customer name
  Future<void> clearCartByCustomer(String customerName);

  /// Get cart items by customer name
  Future<List<Map<String, dynamic>>> getCartItemsByCustomer(String customerName);

  /// Insert cart item for specific customer
  Future<void> insertCartItemForCustomer(Map<String, dynamic> itemData, String customerName);
}