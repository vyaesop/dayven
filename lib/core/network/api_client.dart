abstract class ApiClient {
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
  });

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  });

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, dynamic>? body,
  });

  Future<void> delete(
    String path, {
    Map<String, dynamic>? body,
  });
}
