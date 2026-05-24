import 'dart:io';
import 'api_client.dart';

/// Unified service for all backend data operations.
/// Used by [WaterPlantRepository] when useBackend = true.
class ApiDataService {
  const ApiDataService(this._client);
  final ApiClient _client;

  // ─── Shop ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getShop() => _client.get('/shop');

  Future<Map<String, dynamic>> updateShop(Map<String, dynamic> data) =>
      _client.put('/shop', data);

  Future<Map<String, dynamic>> getListedShops({String? query}) =>
      _client.get('/shop/listed', queryParams: query != null ? {'q': query} : null);

  Future<Map<String, dynamic>> getPublicShop(String shopId) =>
      _client.get('/shop/public/$shopId');

  // ─── Customers ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listCustomers({
    String? query,
    String? status,
    String? billingMode,
  }) =>
      _client.get('/customers', queryParams: {
        if (query != null) 'q': query,
        if (status != null) 'status': status,
        if (billingMode != null) 'billingMode': billingMode,
      });

  Future<Map<String, dynamic>> getCustomer(String id) =>
      _client.get('/customers/$id');

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data) =>
      _client.post('/customers', data);

  Future<Map<String, dynamic>> updateCustomer(String id, Map<String, dynamic> data) =>
      _client.put('/customers/$id', data);

  Future<Map<String, dynamic>> deleteCustomer(String id) =>
      _client.delete('/customers/$id');

  Future<Map<String, dynamic>> getMyLinkedCustomers() =>
      _client.get('/customers/me/linked');

  Future<Map<String, dynamic>> updateMyDeliveryProfile(Map<String, dynamic> data) =>
      _client.patch('/customers/me/delivery-profile', data);

  Future<Map<String, dynamic>> blockCustomer(String id, bool blocked) =>
      _client.patch('/customers/$id/block', {'blocked': blocked});

  // ─── Drivers ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listDrivers() => _client.get('/drivers');

  Future<Map<String, dynamic>> getDriver(String id) => _client.get('/drivers/$id');

  Future<Map<String, dynamic>> createDriver(Map<String, dynamic> data) =>
      _client.post('/drivers', data);

  Future<Map<String, dynamic>> updateDriver(String id, Map<String, dynamic> data) =>
      _client.put('/drivers/$id', data);

  Future<Map<String, dynamic>> setDriverActive(String id, bool active) =>
      _client.patch('/drivers/$id/active', {'active': active});

  Future<Map<String, dynamic>> deleteDriver(String id) =>
      _client.delete('/drivers/$id');

  Future<Map<String, dynamic>> getMyDriverProfile() =>
      _client.get('/drivers/me/profile');

  Future<Map<String, dynamic>> setMyDriverAvailability(bool active) =>
      _client.patch('/drivers/me/availability', {'active': active});

  // ─── Products ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listProducts({bool? activeOnly, String? query}) =>
      _client.get('/products', queryParams: {
        if (activeOnly == true) 'active': 'true',
        if (query != null) 'q': query,
      });

  Future<Map<String, dynamic>> getProduct(String id) =>
      _client.get('/products/$id');

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) =>
      _client.post('/products', data);

  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> data) =>
      _client.put('/products/$id', data);

  Future<Map<String, dynamic>> setProductActive(String id, bool active) =>
      _client.patch('/products/$id/active', {'active': active});

  Future<Map<String, dynamic>> deleteProduct(String id) =>
      _client.delete('/products/$id');

  // ─── Orders ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listOrders({
    String? status,
    String? customerId,
    String? driverId,
    int limit = 50,
    int skip = 0,
  }) =>
      _client.get('/orders', queryParams: {
        if (status != null) 'status': status,
        if (customerId != null) 'customerId': customerId,
        if (driverId != null) 'driverId': driverId,
        'limit': limit.toString(),
        'skip': skip.toString(),
      });

  Future<Map<String, dynamic>> getOrder(String id) => _client.get('/orders/$id');

  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> data) =>
      _client.post('/orders', data);

  Future<Map<String, dynamic>> acceptOrder(String id, {String? adminNote}) =>
      _client.patch('/orders/$id/accept', {if (adminNote != null) 'adminNote': adminNote});

  Future<Map<String, dynamic>> rejectOrder(String id, {String? adminNote}) =>
      _client.patch('/orders/$id/reject', {if (adminNote != null) 'adminNote': adminNote});

  Future<Map<String, dynamic>> assignDriver(String id, String driverId, String? driverName) =>
      _client.patch('/orders/$id/assign', {'driverId': driverId, if (driverName != null) 'driverName': driverName});

  Future<Map<String, dynamic>> driverAcceptOrder(String id) =>
      _client.patch('/orders/$id/driver-accept', {});

  Future<Map<String, dynamic>> updateOrderStatus(String id, String status) =>
      _client.patch('/orders/$id/status', {'status': status});

  Future<Map<String, dynamic>> getMyOrders() => _client.get('/orders/customer/mine');

  Future<Map<String, dynamic>> updateMyPendingOrder(
    String id, {
    required int normalQty,
    required int coolQty,
    String? customerNote,
  }) =>
      _client.patch('/orders/$id/customer', {
        'normalQty': normalQty,
        'coolQty': coolQty,
        if (customerNote != null) 'customerNote': customerNote,
      });

  Future<Map<String, dynamic>> cancelMyOrder(String id) =>
      _client.delete('/orders/$id');

  // ─── Deliveries ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listDeliveries({
    String? customerId,
    String? driverId,
    String? date,
    String? startDate,
    String? endDate,
    int limit = 50,
    int skip = 0,
  }) =>
      _client.get('/deliveries', queryParams: {
        if (customerId != null) 'customerId': customerId,
        if (driverId != null) 'driverId': driverId,
        if (date != null) 'date': date,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        'limit': limit.toString(),
        'skip': skip.toString(),
      });

  Future<Map<String, dynamic>> getDelivery(String id) =>
      _client.get('/deliveries/$id');

  Future<Map<String, dynamic>> createDelivery(Map<String, dynamic> data) =>
      _client.post('/deliveries', data);

  Future<Map<String, dynamic>> updateDelivery(String id, Map<String, dynamic> data) =>
      _client.put('/deliveries/$id', data);

  Future<Map<String, dynamic>> deleteDelivery(String id) =>
      _client.delete('/deliveries/$id');

  // ─── Cash Collections ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listCashCollections({
    String? customerId,
    String? startDate,
    String? endDate,
    int limit = 50,
    int skip = 0,
  }) =>
      _client.get('/cash', queryParams: {
        if (customerId != null) 'customerId': customerId,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        'limit': limit.toString(),
        'skip': skip.toString(),
      });

  Future<Map<String, dynamic>> getPendingAmount(String customerId) =>
      _client.get('/cash/pending/$customerId');

  Future<Map<String, dynamic>> recordCashCollection(Map<String, dynamic> data) =>
      _client.post('/cash', data);

  Future<Map<String, dynamic>> updateCashCollection(String id, Map<String, dynamic> data) =>
      _client.put('/cash/$id', data);

  Future<Map<String, dynamic>> deleteCashCollection(String id) =>
      _client.delete('/cash/$id');

  // ─── Monthly Bills ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listBills({
    String? customerId,
    String? status,
    int? month,
    int? year,
  }) =>
      _client.get('/bills', queryParams: {
        if (customerId != null) 'customerId': customerId,
        if (status != null) 'status': status,
        if (month != null) 'month': month.toString(),
        if (year != null) 'year': year.toString(),
      });

  Future<Map<String, dynamic>> getBill(String id) => _client.get('/bills/$id');

  Future<Map<String, dynamic>> generateBill(String customerId, int month, int year) =>
      _client.post('/bills/generate', {'customerId': customerId, 'month': month, 'year': year});

  Future<Map<String, dynamic>> updateBillStatus(String id, String status) =>
      _client.patch('/bills/$id/status', {'status': status});

  Future<Map<String, dynamic>> getMyBills(String shopId) =>
      _client.get('/bills/customer/mine', queryParams: {'shopId': shopId});

  // ─── Notifications ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listNotifications({bool? unreadOnly}) =>
      _client.get('/notifications', queryParams: {
        if (unreadOnly == true) 'unread': 'true',
      });

  Future<Map<String, dynamic>> markNotificationRead(String id) =>
      _client.patch('/notifications/$id/read', {});

  Future<Map<String, dynamic>> markAllNotificationsRead() =>
      _client.patch('/notifications/read-all', {});

  Future<Map<String, dynamic>> sendNotification(Map<String, dynamic> data) =>
      _client.post('/notifications', data);

  Future<Map<String, dynamic>> deleteNotification(String id) =>
      _client.delete('/notifications/$id');

  // ─── Promotions ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> listPromotions({String? shopId, bool? activeOnly}) =>
      _client.get('/promotions', queryParams: {
        if (shopId != null) 'shopId': shopId,
        if (activeOnly == false) 'active': 'false',
      });

  Future<Map<String, dynamic>> createPromotion(Map<String, dynamic> data) =>
      _client.post('/promotions', data);

  Future<Map<String, dynamic>> updatePromotion(String id, Map<String, dynamic> data) =>
      _client.put('/promotions/$id', data);

  Future<Map<String, dynamic>> setPromotionActive(String id, bool active) =>
      _client.patch('/promotions/$id/active', {'active': active});

  Future<Map<String, dynamic>> deletePromotion(String id) =>
      _client.delete('/promotions/$id');

  // ─── Reports ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats({int? month, int? year}) =>
      _client.get('/reports/dashboard', queryParams: {
        if (month != null) 'month': month.toString(),
        if (year != null) 'year': year.toString(),
      });

  Future<Map<String, dynamic>> getDailyReport(String date) =>
      _client.get('/reports/daily', queryParams: {'date': date});

  Future<Map<String, dynamic>> getMonthlyReport({int? month, int? year}) =>
      _client.get('/reports/monthly', queryParams: {
        if (month != null) 'month': month.toString(),
        if (year != null) 'year': year.toString(),
      });

  Future<Map<String, dynamic>> getPendingReport() =>
      _client.get('/reports/pending');

  // ─── Uploads ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> uploadImage(File file) =>
      _client.postMultipart('/uploads/image', 'file', file);
}
