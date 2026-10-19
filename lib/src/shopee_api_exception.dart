/// A transport, HTTP, GraphQL or response-contract failure.
///
/// [errors] and [partialData] retain upstream details for deliberate handling.
/// Do not log them automatically: an upstream service can echo request data.
/// [toString] intentionally excludes response bodies and request credentials.
final class ShopeeApiException implements Exception {
  ShopeeApiException({
    required this.kind,
    this.statusCode,
    this.retryAfter,
    List<Map<String, dynamic>> errors = const [],
    Map<String, dynamic>? partialData,
  }) : errors = List.unmodifiable(
         errors.map((error) => Map<String, dynamic>.unmodifiable(error)),
       ),
       partialData = partialData == null
           ? null
           : Map<String, dynamic>.unmodifiable(partialData);

  /// One of: http, graphql, timeout, transport, invalidResponse, unsupportedLink.
  final String kind;
  final int? statusCode;

  /// Raw Retry-After HTTP header (seconds or HTTP date), when supplied.
  final String? retryAfter;
  final List<Map<String, dynamic>> errors;
  final Map<String, dynamic>? partialData;

  /// Provider error codes; HTTP 200 can still carry GraphQL errors.
  List<int> get codes => List.unmodifiable(
    errors.expand((error) {
      final extensions = error['extensions'];
      final code = extensions is Map ? extensions['code'] : null;
      return code is int ? [code] : <int>[];
    }),
  );

  bool get isRateLimited => statusCode == 429 || codes.contains(10030);
  bool get isAuthenticationError => statusCode == 401 || codes.contains(10020);
  bool get isAccessDenied => statusCode == 403 || codes.contains(10035);

  @override
  String toString() =>
      'ShopeeApiException(kind: $kind, '
      'statusCode: $statusCode, codes: $codes)';
}

/// Object-oriented programming: Encapsulation a package.
/*
   Learn more: url_to_document_of_package
   How to use?
   STEP 1: Define

   STEP 2: Setup on init
   OPTION 1:

   STEP 3: E.g use
   OPTION 1:

*/
// Help: https://dart.dev/language#classes
// ShopeeApiException.origin()
//   : shopeeApiException = "", assert(shopeeApiException == ""),
// exampleShopeeApiException = abc;
