/// API related constants
class ApiConstants {
  ApiConstants._();

  /// HTTP Methods
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String delete = 'DELETE';
  static const String patch = 'PATCH';

  /// Content Types
  static const String contentTypeJson = 'application/json';
  static const String contentTypeForm = 'application/x-www-form-urlencoded';
  static const String contentTypeMultipart = 'multipart/form-data';

  /// Headers
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String headerAuthorization = 'Authorization';
  static const String headerCookie = 'Cookie';
  static const String headerSetCookie = 'set-cookie';

  /// JSON-RPC
  static const String jsonRpcVersion = '2.0';
  static const String jsonRpcMethod = 'call';

  /// Odoo Common Services
  static const String serviceCommon = 'common';
  static const String serviceObject = 'object';
  static const String serviceDb = 'db';

  /// Odoo Methods
  static const String methodAuthenticate = 'authenticate';
  static const String methodSearchRead = 'search_read';
  static const String methodSearch = 'search';
  static const String methodRead = 'read';
  static const String methodCreate = 'create';
  static const String methodWrite = 'write';
  static const String methodUnlink = 'unlink';
  static const String methodExecuteKw = 'execute_kw';

  /// HTTP Status Codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusNoContent = 204;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusInternalError = 500;
}
