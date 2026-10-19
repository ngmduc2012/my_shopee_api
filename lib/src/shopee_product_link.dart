/// Product identifiers extracted from a supported Vietnamese Shopee URL.
/// Keeps the original affiliate URL so callers do not lose its attribution.
final class ShopeeProductLink {
  const ShopeeProductLink._({
    required this.originalUrl,
    required this.resolvedUrl,
    required this.shopId,
    required this.itemId,
  });

  final Uri originalUrl;
  final Uri resolvedUrl;
  final int shopId;
  final int itemId;

  /// Only these HTTPS hosts are eligible for redirect resolution in v0.1.
  static bool isAllowed(Uri uri) =>
      uri.scheme == 'https' &&
      uri.userInfo.isEmpty &&
      uri.port == 443 &&
      const {
        'shopee.vn',
        'www.shopee.vn',
        's.shopee.vn',
        'shope.ee',
      }.contains(uri.host.toLowerCase());

  /// Parses /product/{shop}/{item} or a product slug ending in -i.{shop}.{item}.
  /// Short links need [MyShopeeApi.resolveProductLink] before they can be parsed.
  static ShopeeProductLink? tryParse(Uri uri, {Uri? originalUrl}) {
    if (!isAllowed(uri) ||
        !const {
          'shopee.vn',
          'www.shopee.vn',
        }.contains(uri.host.toLowerCase())) {
      return null;
    }
    final match =
        RegExp(r'^/product/([0-9]+)/([0-9]+)/?$').firstMatch(uri.path) ??
        RegExp(r'^/[^/]+-i\.([0-9]+)\.([0-9]+)/?$').firstMatch(uri.path);
    if (match == null) return null;
    final shopId = int.tryParse(match.group(1)!);
    final itemId = int.tryParse(match.group(2)!);
    if (shopId == null ||
        itemId == null ||
        shopId <= 0 ||
        itemId <= 0 ||
        shopId > 9007199254740991 ||
        itemId > 9007199254740991) {
      return null;
    }
    return ShopeeProductLink._(
      originalUrl: originalUrl ?? uri,
      resolvedUrl: uri,
      shopId: shopId,
      itemId: itemId,
    );
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
// ShopeeProductLink.origin()
//   : shopeeProductLink = "", assert(shopeeProductLink == ""),
// exampleShopeeProductLink = abc;
