# my_shopee_api

Client Dart cho **Shopee Affiliate Open API**, dùng được trong Flutter hoặc Dart
CLI/server. Đây là package cộng đồng, không phải SDK chính thức của Shopee.

Phiên bản chuẩn bị: `0.1.0`. Chưa publish lên pub.dev và chưa kiểm API thật bằng
credential được cấp quyền. Tài liệu API đối chiếu ngày 2026-10-18.

## Phạm vi

- `getProductOffers`: tìm offer theo shop/item, từ khóa, danh mục; phân trang.
- `getProductOffer`: lấy đúng một offer theo `shopId` và `itemId`, hoặc trả `null`.
- `generateShortLink`: tạo link affiliate với tối đa 5 `subIds`.
- `resolveProductLink` / `getProductFromLink`: hỗ trợ link sản phẩm Việt Nam và
  redirect HTTP thông thường; giữ nguyên link affiliate đầu vào.
- `execute`: GraphQL tùy chỉnh, hỗ trợ variables và operationName.
- Không chứa Firebase, UI, persistence, scraping HTML hay API quản lý catalog.
  Go có thể triển khai client riêng theo cùng contract; không import package Dart.

## Gọi trực tiếp từ Flutter

Bạn cần **AppID + Secret đã được cấp quyền Shopee Affiliate Open API**. Package
không thay thế bước đăng ký quyền API, không dùng cookie đăng nhập Shopee.

Direct mode dành cho môi trường cá nhân tin cậy hoặc server. Với công cụ cá nhân,
nhập khóa lúc chạy và chỉ giữ trong bộ nhớ; package không tự lưu/log khóa. Không
nhúng khóa trong source, assets, `.env` đóng gói, `--dart-define`, localStorage hay
Firestore để gửi cho người dùng. Đăng nhập admin và obfuscation không giấu được
Secret trong ứng dụng Flutter/web đã phân phối. Khi triển khai admin công khai,
đưa client ký request lên backend hoặc một function tin cậy.

**Web:** package biên dịch được sang JavaScript, nhưng request thật còn phụ thuộc
CORS phía Shopee. Chưa xác nhận Shopee cho phép origin web của bạn gọi trực tiếp.
Browser có thể chặn đọc redirect short link; khi đó nhập URL sản phẩm đầy đủ hoặc
shop/item ID. Không tắt bảo mật trình duyệt và không dùng proxy công cộng để gửi khóa.

## Cài local

Yêu cầu Dart >= 3.9. Đã kiểm bằng toolchain Flutter 3.41.2 / Dart 3.11 của repo.
Package cố ý đứng riêng, không tham gia workspace chứa các core nội bộ.

```yaml
dependencies:
  my_shopee_api:
    path: ../../packages/api_clients/my_shopee_api
```

Đường dẫn trên áp dụng từ app trong `apps/`. Sau khi maintainer publish mới dùng
dependency hosted `my_shopee_api: ^0.1.0`.

## Sử dụng

```dart
import 'package:my_shopee_api/my_shopee_api.dart';

Future<void> loadOffers(String appId, String secret) async {
  final api = MyShopeeApi(
    credentials: ShopeeCredentials(appId: appId, secret: secret),
  );
  try {
    final page = await api.getProductOffers(keyword: 'trầm hương', limit: 10);
    for (final product in page.nodes) {
      print('${product.productName}: ${product.priceMin}');
      // product.imageUrl là URL; ứng dụng tự quyết định nơi lưu metadata.
    }
    if (page.pageInfo.hasNextPage) {
      final next = await api.getProductOffers(
        keyword: 'trầm hương', page: page.pageInfo.page + 1, limit: 10,
      );
      print(next.nodes.length);
    }
  } on ShopeeApiException catch (error) {
    // toString không in raw body, thông báo upstream hay credentials.
    print(error);
  } finally {
    api.close();
  }
}
```

Nhập một link hoặc một danh sách link tuần tự:

```dart
Future<void> importLinks(MyShopeeApi api, List<Uri> links) async {
  for (final link in links) {
    try {
      final result = await api.getProductFromLink(link);
      if (result.product == null) continue; // Không có offer, không suy ra hết hàng.
      // Gửi result.product và result.affiliateUrl sang phần lưu nháp của admin.
      // Lỗi một link không làm mất kết quả các link đã xử lý.
    } on ShopeeApiException catch (error) {
      if (error.isRateLimited || error.isAccessDenied ||
          error.isAuthenticationError) rethrow;
      print(error); // UI có thể đánh dấu riêng link lỗi và cho thử lại.
    }
  }
}
```

`generateShortLink(originUrl: Uri.parse('https://shopee.vn/product/1/2'),
subIds: ['campaign'])` là mutation, không tự retry. Nếu đã có link affiliate của
bạn, giữ nguyên link đó làm CTA; không thay bằng `productLink` mất tracking.

## Contract và lỗi

- Endpoint mặc định: `https://open-api.affiliate.shopee.vn/graphql`.
- POST JSON, Authorization theo SHA256(AppID + timestamp + **đúng body gửi** + Secret),
  không phải HMAC. Timestamp dùng giây UTC; đồng hồ lệch quá 10 phút có thể bị từ chối.
- `getProductOffers` dùng `priceMin`/`priceMax` dạng chuỗi để giữ số thập phân.
  `shopName` là tên shop, không được coi là thương hiệu. Không có đảm bảo tồn kho.
- Chỉ khai báo trường hỗ trợ ở v0.1; có thể dùng `execute` để lấy thêm trường theo
  tài liệu Shopee. `sortType` 1–5; loại 1 yêu cầu keyword. Không tự tải tất cả trang.
- IDs giới hạn số nguyên chính xác chung Dart VM/web: tối đa 9007199254740991.
- `http`: HTTP khác 200, gồm redirect (không chuyển tiếp Authorization).
- `graphql`: `errors` có dữ liệu kể cả HTTP 200. Có `codes`, `partialData`,
  `isRateLimited` (10030/429), `isAuthenticationError` (10020/401),
  `isAccessDenied` (10035/403). Không tự coi partial response là thành công.
- `invalidResponse`: JSON/envelope/model sai contract; `transport`: lỗi mạng/CORS;
  `timeout`: quá thời gian; `unsupportedLink`: link không hỗ trợ/CAPTCHA/redirect lặp.
- Timeout mặc định 20 giây **mỗi request**; có yêu cầu hủy request cho HTTP client
  hỗ trợ `AbortableRequest`. Không retry ngầm, đặc biệt với mutation.
- `errors`/`partialData` giữ nguyên dữ liệu upstream cho caller xử lý; không log tự
  động vì upstream có thể phản chiếu dữ liệu đầu vào.
- `close()` chỉ đóng client SDK tự tạo. Khi truyền `httpClient`, caller tự đóng nó.
- Link VN: `shopee.vn`, `www.shopee.vn`, `s.shopee.vn`, `shope.ee`, chỉ HTTPS/443,
  không userinfo. Tối đa 5 redirect mặc định; không đọc HTML/JS, không vượt CAPTCHA.
- Tài liệu Shopee hiện ghi hạn mức 8000 request/giờ; đây là chính sách provider có
  thể đổi. Gặp rate limit phải dừng/backoff, không tiếp tục toàn bộ batch.

## Kiểm thử và phát hành

Chạy trong thư mục package (bỏ `fvm` nếu dùng Dart SDK độc lập phù hợp):

```sh
fvm dart pub get
fvm dart run build_runner build
fvm dart format lib test example
fvm dart analyze
fvm dart test
fvm dart run example/my_shopee_api_example.dart
fvm dart doc --output build/api
fvm dart pub publish --dry-run
```

Ví dụ mặc định dùng dữ liệu giả và không gửi request ra internet. Hướng dẫn kiểm
HTTP thật với server giả lập local: [postman/README.md](postman/README.md) (cần Postman CLI 1.70+).

Trước publish: kiểm API thật bằng tài khoản có quyền, kiểm CORS nếu quảng bá direct
web, chọn repository công khai và bổ sung URL đã tồn tại vào pubspec; rà nội dung
archive bằng dry-run. Tên trên pub.dev chưa được giữ chỗ. Maintainer tự chạy
`dart pub publish` sau khi hoàn tất; tác vụ hiện tại không upload/publish.

Kết quả local 2026-10-18: analyze sạch, 41 unit tests đạt (gồm chữ ký đúng ví dụ
Shopee), ví dụ offline và 6 request qua Postman simulation đạt; compile JavaScript
đạt; publish dry-run **0 cảnh báo**, archive có đủ 3 file `.g.dart`. API thật và
CORS chưa kiểm. Đây là SDK riêng, chưa có Flutter app nào đang dùng để hot reload.

## Nguồn chính thức

- [Authentication](https://affiliate.shopee.vn/open_api/document?type=authentication)
- [Request/Response](https://affiliate.shopee.vn/open_api/document?type=request_response)
- [Product offers](https://affiliate.shopee.vn/open_api/list?type=product_offer)
- [Generate short link](https://affiliate.shopee.vn/open_api/list?type=short_link)
- [Hạn mức](https://affiliate.shopee.vn/open_api/document?type=overview)

Giấy phép mã nguồn: [MIT](LICENSE). Quyền sử dụng API/nội dung Shopee do Shopee quản lý.
