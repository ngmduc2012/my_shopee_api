import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_shopee_api/my_shopee_api.dart';
import 'package:test/test.dart';

void main() {
  final credentials = ShopeeCredentials(appId: '123456', secret: 'demo');
  for (final value in [
    'https://shopee.vn/product/1302304039/24495305741?utm_source=test',
    'https://shopee.vn/Thac-nuoc-i.1302304039.24495305741',
    'https://www.shopee.vn/product/1302304039/24495305741/',
  ]) {
    test('parses product identifiers: $value', () {
      final result = ShopeeProductLink.tryParse(Uri.parse(value));
      expect(result?.shopId, 1302304039);
      expect(result?.itemId, 24495305741);
      expect(result?.originalUrl.toString(), value);
    });
  }

  for (final value in [
    'https://shopee.vn.evil.test/product/1/2',
    'https://user:pass@shopee.vn/product/1/2',
    'http://shopee.vn/product/1/2',
    'https://shopee.vn:444/product/1/2',
    'https://127.0.0.1/product/1/2',
    'https://shopee.vn/product/0/2',
    'https://shopee.vn/product/1/9007199254740992',
    'https://shopee.vn/login?next=/product/1/2',
    'https://s.shopee.vn/demo',
  ]) {
    test('does not misparse unsafe/non-product link: $value', () {
      expect(ShopeeProductLink.tryParse(Uri.parse(value)), isNull);
    });
  }

  test('direct product links require no HTTP calls', () async {
    final api = MyShopeeApi(
      credentials: credentials,
      httpClient: MockClient((_) async => fail('unexpected call')),
    );
    expect(
      (await api.resolveProductLink(
        Uri.parse('https://shopee.vn/product/1/2'),
      )).itemId,
      2,
    );
  });

  test(
    'resolves redirect without API credentials and keeps affiliate attribution',
    () async {
      final api = MyShopeeApi(
        credentials: credentials,
        httpClient: MockClient((request) async {
          expect(
            request.headers.keys.map((key) => key.toLowerCase()),
            isNot(contains('authorization')),
          );
          expect(request.followRedirects, isFalse);
          return http.Response(
            '',
            302,
            headers: {'location': 'https://shopee.vn/product/1/2'},
          );
        }),
      );
      final result = await api.resolveProductLink(
        Uri.parse('https://s.shopee.vn/demo'),
      );
      expect(result.itemId, 2);
      expect(result.originalUrl.toString(), 'https://s.shopee.vn/demo');
    },
  );

  for (final redirect in [
    'https://example.com/product/1/2',
    'http://127.0.0.1/product/1/2',
    'https://s.shopee.vn/demo',
  ]) {
    test('blocks redirect host changes and loops: $redirect', () async {
      var count = 0;
      final api = MyShopeeApi(
        credentials: credentials,
        httpClient: MockClient((_) async {
          count++;
          return http.Response('', 302, headers: {'location': redirect});
        }),
      );
      await expectLater(
        api.resolveProductLink(Uri.parse('https://s.shopee.vn/demo')),
        throwsA(
          isA<ShopeeApiException>().having(
            (e) => e.kind,
            'kind',
            'unsupportedLink',
          ),
        ),
      );
      expect(count, 1);
    });
  }

  test('bounded redirects and CAPTCHA/HTML produce unsupportedLink', () async {
    var calls = 0;
    final api = MyShopeeApi(
      credentials: credentials,
      httpClient: MockClient((_) async {
        calls++;
        return http.Response('', 302, headers: {'location': '/redirect$calls'});
      }),
    );
    await expectLater(
      api.resolveProductLink(
        Uri.parse('https://s.shopee.vn/demo'),
        maxRedirects: 1,
      ),
      throwsA(isA<ShopeeApiException>()),
    );
    expect(calls, 2);
    final captcha = MyShopeeApi(
      credentials: credentials,
      httpClient: MockClient(
        (_) async => http.Response('<html>Verify to continue</html>', 200),
      ),
    );
    await expectLater(
      captcha.resolveProductLink(Uri.parse('https://s.shopee.vn/demo')),
      throwsA(
        isA<ShopeeApiException>().having(
          (e) => e.kind,
          'kind',
          'unsupportedLink',
        ),
      ),
    );
  });

  test('import preserves original link and matches product metadata', () async {
    final api = MyShopeeApi(
      credentials: credentials,
      httpClient: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            '',
            302,
            headers: {'location': 'https://shopee.vn/product/1/2'},
          );
        }
        return http.Response(
          jsonEncode({
            'data': {
              'productOfferV2': {
                'nodes': [
                  {'shopId': 1, 'itemId': 2, 'productName': 'Demo'},
                ],
                'pageInfo': {'page': 1, 'limit': 20, 'hasNextPage': false},
              },
            },
          }),
          200,
        );
      }),
    );
    final result = await api.getProductFromLink(
      Uri.parse('https://s.shopee.vn/affiliate-demo'),
    );
    expect(
      result.affiliateUrl.toString(),
      'https://s.shopee.vn/affiliate-demo',
    );
    expect(result.product?.productName, 'Demo');
  });
}

/*
 Learn more: https://docs.flutter.dev/cookbook/testing/unit/introduction
 A unit test tests a single function, method, or class.
*/
/// Remind comment on tested function: // #TESTED
/// Remind comment on tested widget: // #TESTED
