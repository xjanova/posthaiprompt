// Thaiprompt POS — Typed surface over the LIVE PosTerminalController.
//
// Endpoints confirmed against the deployed server (main.thaiprompt.online).
// Catalog/order endpoints are POST and authenticate via the terminal headers
// (X-API-Key / X-Product-Key / X-Device-ID) attached by ApiClient.
//
// by xman studio

import 'api_client.dart';
import 'api_config.dart';

class PosApi {
  final ApiClient client;
  final ApiConfig config;
  PosApi(this.client, this.config);

  /// Public health check — no auth.
  Future<Map<String, dynamic>> ping() async =>
      (await client.get(ApiPaths.ping) as Map).cast<String, dynamic>();

  /// Confirm the terminal is registered + verified (needs the 3 headers).
  /// Returns `{success, valid, ...}`.
  Future<Map<String, dynamic>> validate() async =>
      (await client.get(ApiPaths.validate) as Map).cast<String, dynamic>();

  /// Pull the shop's real products. Returns the `data` array:
  /// `[{id, sku, barcode, name, price, cost, stock, category_id, category_name, image_url, updated_at}]`
  Future<List<dynamic>> syncProducts() => _postList(ApiPaths.syncProducts);

  /// Pull the shop's categories: `[{id, name, icon, color, sort_order}]`.
  Future<List<dynamic>> syncCategories() => _postList(ApiPaths.syncCategories);

  /// Push completed orders. Body shape per the server:
  /// `{orders:[{local_id, total, items:[{product_id?, name, quantity, price}], created_at}]}`
  Future<Map<String, dynamic>> uploadOrders(List<Map<String, dynamic>> orders) async =>
      (await client.post(ApiPaths.syncOrders, data: {'orders': orders}) as Map).cast<String, dynamic>();

  Future<Map<String, dynamic>> reportSales(Map<String, dynamic> body) async =>
      (await client.post(ApiPaths.reportSales, data: body) as Map).cast<String, dynamic>();

  /// Pairing helpers (admin issues the API key out-of-band).
  Future<Map<String, dynamic>> registerDevice(Map<String, dynamic> body) async =>
      (await client.post(ApiPaths.registerDevice, data: body) as Map).cast<String, dynamic>();

  Future<Map<String, dynamic>> verify(Map<String, dynamic> body) async =>
      (await client.post(ApiPaths.verify, data: body) as Map).cast<String, dynamic>();

  Future<List<dynamic>> _postList(String path) async {
    final data = await client.post(path);
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }
}
