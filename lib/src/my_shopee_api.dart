import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';

import 'models/shopee_product_offer_entity.dart';
import 'models/shopee_product_page_entity.dart';
import 'shopee_api_exception.dart';
import 'shopee_credentials.dart';
import 'shopee_product_link.dart';

/// Direct client for Shopee Affiliate Open API. Does not persist credentials.
///
/// Browser requests remain subject to Shopee CORS policy. Embedding credentials
/// in a public Flutter/web application exposes them; a private admin login does
/// not make JavaScript secrets private. No request is automatically retried.
final class MyShopeeApi {
  MyShopeeApi({
    required ShopeeCredentials credentials,
    http.Client? httpClient,
    Uri? endpoint,
    Duration timeout = const Duration(seconds: 20),
    DateTime Function()? clock,
  }) : _credentials = credentials,
       endpoint =
           endpoint ??
           Uri.parse('https://open-api.affiliate.shopee.vn/graphql'),
       _timeout = timeout,
       _clock = clock ?? DateTime.now,
       _client = httpClient ?? http.Client(),
       _ownsClient = httpClient == null {
    final local =
        this.endpoint.scheme == 'http' &&
        const {'localhost', '127.0.0.1', '::1'}.contains(this.endpoint.host);
    if ((!local && this.endpoint.scheme != 'https') ||
        this.endpoint.host.isEmpty ||
        this.endpoint.userInfo.isNotEmpty ||
        this.endpoint.hasQuery ||
        this.endpoint.hasFragment) {
      throw ArgumentError(
        'endpoint must be HTTPS, or HTTP loopback for tests.',
      );
    }
    if (timeout <= Duration.zero) {
      throw ArgumentError('timeout must be positive.');
    }
  }

  final ShopeeCredentials _credentials;
  final http.Client _client;
  final bool _ownsClient;
  final Duration _timeout;
  final DateTime Function() _clock;
  final Uri endpoint;
  bool _closed = false;

  /// Executes a GraphQL operation. All upstream errors throw, including partial
  /// failures with HTTP 200. Partial results are on ShopeeApiException.partialData.
  Future<Map<String, dynamic>> execute({
    required String query,
    Map<String, dynamic>? variables,
    String? operationName,
  }) async {
    _ensureOpen();
    if (query.trim().isEmpty) throw ArgumentError('query must not be empty.');
    final payload = jsonEncode({
      'query': query,
      if (operationName != null) 'operationName': operationName,
      if (variables != null) 'variables': variables,
    });
    final authorization = _credentials.authorization(
      payload: payload,
      timestamp: _clock().toUtc().millisecondsSinceEpoch ~/ 1000,
    );
    final response = await _request(
      endpoint,
      method: 'POST',
      body: payload,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
        'Authorization': authorization,
      },
    );
    if (response.statusCode != 200) {
      throw ShopeeApiException(
        kind: 'http',
        statusCode: response.statusCode,
        retryAfter: response.headers['retry-after'],
      );
    }
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      json = decoded;
    } on FormatException {
      throw ShopeeApiException(kind: 'invalidResponse', statusCode: 200);
    }
    final rawErrors = json['errors'];
    if (rawErrors != null) {
      if (rawErrors is! List ||
          rawErrors.any((error) => error is! Map<String, dynamic>)) {
        throw ShopeeApiException(kind: 'invalidResponse', statusCode: 200);
      }
      if (rawErrors.isNotEmpty) {
        final data = json['data'];
        throw ShopeeApiException(
          kind: 'graphql',
          statusCode: 200,
          errors: rawErrors.cast<Map<String, dynamic>>(),
          partialData: data is Map<String, dynamic> ? data : null,
        );
      }
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw ShopeeApiException(kind: 'invalidResponse', statusCode: 200);
    }
    return data;
  }

  /// Fetches one page. Strings are JSON-escaped when embedded as GraphQL literals.
  /// IDs must fit the exact integer range shared by Dart VM and compiled web.
  Future<ShopeeProductPageEntity> getProductOffers({
    int? shopId,
    int? itemId,
    int? productCatId,
    String? keyword,
    int? sortType,
    bool? isAMSOffer,
    bool? isKeySeller,
    int page = 1,
    int limit = 20,
  }) async {
    if (page < 1 || limit < 1) {
      throw ArgumentError('page and limit must be positive.');
    }
    for (final id in [shopId, itemId, productCatId]) {
      if (id != null && (id < 1 || id > 9007199254740991)) {
        throw ArgumentError(
          'IDs must be positive, exactly representable integers.',
        );
      }
    }
    if (sortType != null && (sortType < 1 || sortType > 5)) {
      throw ArgumentError('sortType must be between 1 and 5.');
    }
    if (sortType == 1 && (keyword == null || keyword.trim().isEmpty)) {
      throw ArgumentError('Relevance sorting requires a keyword.');
    }
    final args = <String, Object>{
      if (shopId != null) 'shopId': shopId,
      if (itemId != null) 'itemId': itemId,
      if (productCatId != null) 'productCatId': productCatId,
      if (keyword != null) 'keyword': keyword,
      if (sortType != null) 'sortType': sortType,
      if (isAMSOffer != null) 'isAMSOffer': isAMSOffer,
      if (isKeySeller != null) 'isKeySeller': isKeySeller,
      'page': page,
      'limit': limit,
    };
    final arguments = args.entries
        .map((entry) => '${entry.key}: ${jsonEncode(entry.value)}')
        .join(', ');
    final data = await execute(
      query:
          'query { productOfferV2($arguments) { '
          'nodes { itemId shopId productName imageUrl priceMin priceMax shopName '
          'productLink offerLink commissionRate sales ratingStar } '
          'pageInfo { page limit hasNextPage } } }',
    );
    try {
      final connection = data['productOfferV2'];
      if (connection is! Map<String, dynamic>) throw const FormatException();
      return ShopeeProductPageEntity.fromJson(connection);
    } on CheckedFromJsonException {
      throw ShopeeApiException(kind: 'invalidResponse');
    } on FormatException {
      throw ShopeeApiException(kind: 'invalidResponse');
    }
  }

  /// Returns null if the requested product is not returned as an affiliate offer.
  /// This is not a stock-status check.
  Future<ShopeeProductOfferEntity?> getProductOffer({
    required int shopId,
    required int itemId,
  }) async {
    final result = await getProductOffers(shopId: shopId, itemId: itemId);
    for (final product in result.nodes) {
      if (product.shopId == shopId && product.itemId == itemId) return product;
    }
    return null;
  }

  /// Creates an affiliate short link. This mutation is never retried by the SDK.
  Future<Uri> generateShortLink({
    required Uri originUrl,
    List<String> subIds = const [],
  }) async {
    if (!ShopeeProductLink.isAllowed(originUrl)) {
      throw ArgumentError('originUrl must be an allowed Shopee HTTPS URL.');
    }
    if (subIds.length > 5) {
      throw ArgumentError('At most five subIds are supported.');
    }
    final data = await execute(
      query:
          'mutation { generateShortLink(input: { '
          'originUrl: ${jsonEncode(originUrl.toString())}, '
          'subIds: ${jsonEncode(subIds)} }) { shortLink } }',
    );
    final result = data['generateShortLink'];
    final value = result is Map<String, dynamic> ? result['shortLink'] : null;
    final uri = value is String ? Uri.tryParse(value) : null;
    if (uri == null || !ShopeeProductLink.isAllowed(uri)) {
      throw ShopeeApiException(kind: 'invalidResponse');
    }
    return uri;
  }

  /// Resolves supported VN product links and ordinary HTTP redirects only.
  /// No API credentials are sent to product/short-link hosts. CAPTCHA, HTML/JS
  /// redirects, login and unsupported hosts produce unsupportedLink errors.
  Future<ShopeeProductLink> resolveProductLink(
    Uri url, {
    int maxRedirects = 5,
  }) async {
    _ensureOpen();
    if (maxRedirects < 0 || maxRedirects > 10) {
      throw ArgumentError('maxRedirects must be between 0 and 10.');
    }
    var current = url;
    final visited = <Uri>{};
    for (var redirects = 0; redirects <= maxRedirects; redirects++) {
      if (!ShopeeProductLink.isAllowed(current) || !visited.add(current)) {
        throw ShopeeApiException(kind: 'unsupportedLink');
      }
      final parsed = ShopeeProductLink.tryParse(current, originalUrl: url);
      if (parsed != null) return parsed;
      final response = await _request(current, method: 'GET');
      if (!const {301, 302, 303, 307, 308}.contains(response.statusCode)) {
        throw ShopeeApiException(
          kind: response.statusCode >= 400 ? 'http' : 'unsupportedLink',
          statusCode: response.statusCode,
          retryAfter: response.headers['retry-after'],
        );
      }
      final location = response.headers['location'];
      if (location == null) throw ShopeeApiException(kind: 'unsupportedLink');
      try {
        current = current.resolve(location);
      } on FormatException {
        throw ShopeeApiException(kind: 'unsupportedLink');
      }
    }
    throw ShopeeApiException(kind: 'unsupportedLink');
  }

  /// Resolves a link and fetches the exact matching offer, preserving attribution.
  Future<({Uri affiliateUrl, ShopeeProductOfferEntity? product})>
  getProductFromLink(Uri url) async {
    final link = await resolveProductLink(url);
    final product = await getProductOffer(
      shopId: link.shopId,
      itemId: link.itemId,
    );
    return (affiliateUrl: link.originalUrl, product: product);
  }

  Future<http.Response> _request(
    Uri url, {
    required String method,
    String? body,
    Map<String, String> headers = const {},
  }) async {
    _ensureOpen();
    final abort = Completer<void>();
    final request =
        http.AbortableRequest(method, url, abortTrigger: abort.future)
          ..followRedirects = false
          ..headers.addAll(headers);
    if (body != null) request.bodyBytes = utf8.encode(body);
    try {
      return await (() async {
        final response = await _client.send(request);
        return http.Response.fromStream(response);
      })().timeout(_timeout);
    } on TimeoutException {
      if (!abort.isCompleted) abort.complete();
      throw ShopeeApiException(kind: 'timeout');
    } on http.ClientException {
      throw ShopeeApiException(kind: 'transport');
    }
  }

  void _ensureOpen() {
    if (_closed) throw StateError('MyShopeeApi is closed.');
  }

  /// Releases an internally-created HTTP client. An injected client remains
  /// caller-owned and must be closed by its owner.
  void close() {
    if (_closed) return;
    _closed = true;
    if (_ownsClient) _client.close();
  }
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
// MyShopeeApi.origin()
//   : myShopeeApi = "", assert(myShopeeApi == ""),
// exampleMyShopeeApi = abc;
