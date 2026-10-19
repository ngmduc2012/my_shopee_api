import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_shopee_api/my_shopee_api.dart';

/// Runs offline by default. A loopback URL enables the local Postman simulation.
/// These are public Shopee documentation credentials, never real credentials.
Future<void> main(List<String> args) async {
  final Uri? simulation = args.isEmpty ? null : Uri.parse(args.single);
  if (simulation != null &&
      (simulation.scheme != 'http' || simulation.host != '127.0.0.1')) {
    throw ArgumentError(
      'The example only accepts an HTTP loopback simulation.',
    );
  }
  final mock = simulation == null
      ? MockClient(
          (request) async => http.Response(
            jsonEncode({
              'data': {
                'productOfferV2': {
                  'nodes': [
                    {
                      'itemId': 2,
                      'shopId': 1,
                      'productName': 'Sản phẩm minh họa',
                      'imageUrl': 'https://example.com/product.jpg',
                      'priceMin': '100000',
                      'priceMax': '120000',
                    },
                  ],
                  'pageInfo': {'page': 1, 'limit': 20, 'hasNextPage': false},
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        )
      : null;
  final client = MyShopeeApi(
    credentials: ShopeeCredentials(appId: '123456', secret: 'demo'),
    httpClient: mock,
    endpoint: simulation,
    timeout: const Duration(seconds: 2),
  );
  try {
    final result = await client.getProductOffers(keyword: 'trầm hương');
    print(
      '${result.nodes.single.productName}: ${result.nodes.single.priceMin}',
    );
    if (simulation != null) {
      final url = await client.generateShortLink(
        originUrl: Uri.parse('https://shopee.vn/product/1/2'),
        subIds: ['demo'],
      );
      print('Simulation short link: $url');
      for (final scenario in {
        '__rate_limit__': 'graphql',
        '__http_503__': 'http',
        '__invalid_json__': 'invalidResponse',
        '__timeout__': 'timeout',
      }.entries) {
        try {
          await client.getProductOffers(keyword: scenario.key);
          throw StateError('Expected ${scenario.value}');
        } on ShopeeApiException catch (error) {
          if (error.kind != scenario.value) rethrow;
          print('Simulation ${scenario.value}: OK');
        }
      }
    }
  } finally {
    client.close();
    mock?.close();
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
// MyShopeeApiExample.origin()
//   : myShopeeApiExample = "", assert(myShopeeApiExample == ""),
// exampleMyShopeeApiExample = abc;
