import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_shopee_api/my_shopee_api.dart';
import 'package:test/test.dart';

final credentials = ShopeeCredentials(appId: '123456', secret: 'demo');

Map<String, dynamic> pageJson({List<Map<String, dynamic>>? products}) => {
  'nodes':
      products ??
      [
        {
          'itemId': 24495305741,
          'shopId': 1302304039,
          'productName': 'Sản phẩm thử',
          'priceMin': '12345.67',
          'priceMax': '25000',
          'imageUrl': 'https://example.com/demo.jpg',
        },
      ],
  'pageInfo': {'page': 1, 'limit': 20, 'hasNextPage': false},
};

http.Response response(Object? data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

TypeMatcher<ShopeeApiException> failure(String kind) =>
    isA<ShopeeApiException>().having((error) => error.kind, 'kind', kind);

void main() {
  test('signature matches the official Shopee authentication example', () {
    const payload =
        r'{"query":"{\nbrandOffer{\n    nodes{\n        commissionRate\n        offerName\n    }\n}\n}"}';
    expect(
      credentials.authorization(payload: payload, timestamp: 1577836800),
      'SHA256 Credential=123456, Timestamp=1577836800, '
      'Signature=dc88d72feea70c80c52c3399751a7d34966763f51a7f056aa070a5e9df645412',
    );
  });

  test('credentials and errors do not print secrets or provider messages', () {
    expect(credentials.toString(), isNot(contains('demo')));
    final error = ShopeeApiException(
      kind: 'graphql',
      errors: [
        {
          'message': 'demo private payload',
          'extensions': {'code': 10020, 'message': 'demo'},
        },
      ],
    );
    expect(error.isAuthenticationError, isTrue);
    expect(error.toString(), isNot(contains('demo')));
    expect(error.toString(), contains('10020'));
  });

  test('invalid credentials and unsafe endpoints fail locally', () {
    expect(
      () => ShopeeCredentials(appId: 'abc', secret: 's'),
      throwsArgumentError,
    );
    expect(
      () => ShopeeCredentials(appId: '1', secret: ''),
      throwsArgumentError,
    );
    for (final endpoint in [
      'http://example.com/graphql',
      'https://u:p@example.com/graphql',
      'https://example.com/graphql?token=secret',
    ]) {
      expect(
        () => MyShopeeApi(
          credentials: credentials,
          endpoint: Uri.parse(endpoint),
        ),
        throwsArgumentError,
      );
    }
  });

  test(
    'signs the exact UTF-8 JSON sent on the wire and disables redirects',
    () async {
      final api = MyShopeeApi(
        credentials: credentials,
        clock: () =>
            DateTime.fromMillisecondsSinceEpoch(1577836800000, isUtc: true),
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.followRedirects, isFalse);
          expect(
            request.url.toString(),
            'https://open-api.affiliate.shopee.vn/graphql',
          );
          expect(
            request.headers['Authorization'],
            credentials.authorization(
              payload: utf8.decode(request.bodyBytes),
              timestamp: 1577836800,
            ),
          );
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['variables'], {'keyword': 'Trầm "hương"\nViệt'});
          expect(body['operationName'], 'Offers');
          return response({
            'data': {'ok': true},
          });
        }),
      );
      expect(
        await api.execute(
          query: 'query Offers { ok }',
          operationName: 'Offers',
          variables: {'keyword': 'Trầm "hương"\nViệt'},
        ),
        {'ok': true},
      );
    },
  );

  test(
    'typed product offers preserve decimal price strings and page state',
    () async {
      final api = MyShopeeApi(
        credentials: credentials,
        httpClient: MockClient((request) async {
          final query =
              (jsonDecode(request.body) as Map<String, dynamic>)['query']
                  as String;
          expect(query, contains('keyword: ${jsonEncode('Trầm "hương"')}'));
          expect(query, contains('shopId: 1302304039'));
          expect(query, isNot(contains(' price ')));
          return response({
            'data': {'productOfferV2': pageJson()},
          });
        }),
      );
      final result = await api.getProductOffers(
        shopId: 1302304039,
        keyword: 'Trầm "hương"',
      );
      expect(result.nodes.single.priceMin, '12345.67');
      expect(result.nodes.single.productName, 'Sản phẩm thử');
      expect(result.pageInfo.hasNextPage, isFalse);
      expect(() => result.nodes.clear(), throwsUnsupportedError);
      expect(
        ShopeeProductPageEntity.fromJson(result.toJson()).toJson(),
        result.toJson(),
      );
    },
  );

  test('missing offers return null, not a manufactured product', () async {
    final api = MyShopeeApi(
      credentials: credentials,
      httpClient: MockClient(
        (_) async => response({
          'data': {'productOfferV2': pageJson(products: [])},
        }),
      ),
    );
    expect(await api.getProductOffer(shopId: 1, itemId: 2), isNull);
  });

  test('getProductOffer only returns the matching shop and item', () async {
    final api = MyShopeeApi(
      credentials: credentials,
      httpClient: MockClient(
        (_) async => response({
          'data': {'productOfferV2': pageJson()},
        }),
      ),
    );
    expect(await api.getProductOffer(shopId: 1, itemId: 2), isNull);
    expect(
      (await api.getProductOffer(
        shopId: 1302304039,
        itemId: 24495305741,
      ))?.itemId,
      24495305741,
    );
  });

  test(
    'HTTP 200 GraphQL errors retain partial data and provider codes',
    () async {
      final api = MyShopeeApi(
        credentials: credentials,
        httpClient: MockClient(
          (_) async => response({
            'data': {'partial': true},
            'errors': [
              {
                'message': 'rate limited',
                'extensions': {'code': 10030},
              },
            ],
          }),
        ),
      );
      await expectLater(
        api.execute(query: '{ x }'),
        throwsA(
          failure(
            'graphql',
          ).having((error) => error.isRateLimited, 'rate limited', true).having(
            (error) => error.partialData,
            'partial data',
            {'partial': true},
          ),
        ),
      );
    },
  );

  for (final body in [
    '<html>Proxy error</html>',
    '[]',
    '{}',
    '{"errors":"bad"}',
    '{"data":null}',
    '{"errors":["bad"]}',
    '{"data":[]}',
  ]) {
    test('invalid JSON/GraphQL envelope is rejected: $body', () async {
      final api = MyShopeeApi(
        credentials: credentials,
        httpClient: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(
        api.execute(query: '{ x }'),
        throwsA(failure('invalidResponse')),
      );
    });
  }

  test('malformed typed product data becomes invalidResponse', () async {
    final api = MyShopeeApi(
      credentials: credentials,
      httpClient: MockClient(
        (_) async => response({
          'data': {
            'productOfferV2': {
              'nodes': [
                {'itemId': 'bad'},
              ],
              'pageInfo': {'page': 1, 'limit': 20, 'hasNextPage': false},
            },
          },
        }),
      ),
    );
    await expectLater(
      api.getProductOffers(),
      throwsA(failure('invalidResponse')),
    );
  });

  test('HTTP 429 is distinguishable and preserves Retry-After', () async {
    var calls = 0;
    final api = MyShopeeApi(
      credentials: credentials,
      httpClient: MockClient((_) async {
        calls++;
        return http.Response('busy', 429, headers: {'retry-after': '60'});
      }),
    );
    await expectLater(
      api.execute(query: '{ x }'),
      throwsA(
        failure('http')
            .having((error) => error.isRateLimited, 'limited', true)
            .having((error) => error.retryAfter, 'retry after', '60'),
      ),
    );
    expect(calls, 1);
  });

  test('API redirects fail without forwarding authorization', () async {
    var calls = 0;
    final api = MyShopeeApi(
      credentials: credentials,
      httpClient: MockClient((request) async {
        calls++;
        expect(request.followRedirects, isFalse);
        return http.Response(
          '',
          302,
          headers: {'location': 'https://example.com'},
        );
      }),
    );
    await expectLater(api.execute(query: '{ x }'), throwsA(failure('http')));
    expect(calls, 1);
  });

  test('transport failures and timeouts have distinct errors', () async {
    final broken = MyShopeeApi(
      credentials: credentials,
      httpClient: MockClient((_) async {
        throw http.ClientException('private request details');
      }),
    );
    await expectLater(
      broken.execute(query: '{ x }'),
      throwsA(failure('transport')),
    );
    final slow = MyShopeeApi(
      credentials: credentials,
      timeout: const Duration(milliseconds: 5),
      httpClient: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return response({'data': <String, dynamic>{}});
      }),
    );
    await expectLater(
      slow.execute(query: '{ x }'),
      throwsA(failure('timeout')),
    );
  });

  test('short link mutation escapes values and returns provider URL', () async {
    final api = MyShopeeApi(
      credentials: credentials,
      httpClient: MockClient((request) async {
        final query =
            (jsonDecode(request.body) as Map<String, dynamic>)['query']
                as String;
        expect(query, contains('generateShortLink(input:'));
        expect(query, contains(jsonEncode(['campaign"x', 'VN'])));
        return response({
          'data': {
            'generateShortLink': {'shortLink': 'https://s.shopee.vn/demo'},
          },
        });
      }),
    );
    expect(
      (await api.generateShortLink(
        originUrl: Uri.parse('https://shopee.vn/product/1/2'),
        subIds: ['campaign"x', 'VN'],
      )).toString(),
      'https://s.shopee.vn/demo',
    );
    await expectLater(
      api.generateShortLink(
        originUrl: Uri.parse('https://shopee.vn'),
        subIds: List.filled(6, 'x'),
      ),
      throwsArgumentError,
    );
  });

  test('invalid query arguments fail before network requests', () async {
    final api = MyShopeeApi(
      credentials: credentials,
      httpClient: MockClient((_) async => fail('unexpected network call')),
    );
    await expectLater(api.getProductOffers(page: 0), throwsArgumentError);
    await expectLater(api.getProductOffers(limit: 0), throwsArgumentError);
    await expectLater(api.getProductOffers(shopId: -1), throwsArgumentError);
    await expectLater(
      api.getProductOffers(itemId: 9007199254740992),
      throwsArgumentError,
    );
    await expectLater(api.getProductOffers(sortType: 1), throwsArgumentError);
    await expectLater(api.getProductOffers(sortType: 6), throwsArgumentError);
    await expectLater(api.execute(query: ' '), throwsArgumentError);
  });

  test(
    'close is idempotent and does not close the caller-owned client',
    () async {
      final httpClient = MockClient(
        (_) async => response({'data': <String, dynamic>{}}),
      );
      final api = MyShopeeApi(credentials: credentials, httpClient: httpClient);
      api.close();
      api.close();
      await expectLater(api.execute(query: '{ x }'), throwsStateError);
      expect(
        (await httpClient.get(Uri.parse('https://example.com'))).statusCode,
        200,
      );
      httpClient.close();
    },
  );
}

/*
 Learn more: https://docs.flutter.dev/cookbook/testing/unit/introduction
 A unit test tests a single function, method, or class.
*/
/// Remind comment on tested function: // #TESTED
/// Remind comment on tested widget: // #TESTED
