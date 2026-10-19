import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Credentials supplied by the Shopee Affiliate Open API platform.
///
/// This object does not persist credentials. A Flutter application cannot hide
/// a shared secret from the person running it; use direct calls only in a
/// trusted personal environment, or keep this client on your server.
final class ShopeeCredentials {
  ShopeeCredentials({required String appId, required String secret})
    : _appId = appId,
      _secret = secret {
    if (!RegExp(r'^[0-9]+$').hasMatch(appId)) {
      throw ArgumentError('appId must contain digits only.');
    }
    if (secret.isEmpty) throw ArgumentError('secret must not be empty.');
  }

  final String _appId;
  final String _secret;

  /// Signs the exact UTF-8 request body with SHA256, not HMAC.
  /// Never log the returned Authorization header.
  String authorization({required String payload, required int timestamp}) {
    if (timestamp < 0) throw ArgumentError('timestamp must be non-negative.');
    final signature = sha256.convert(
      utf8.encode('$_appId$timestamp$payload$_secret'),
    );
    return 'SHA256 Credential=$_appId, Timestamp=$timestamp, '
        'Signature=$signature';
  }

  @override
  String toString() => 'ShopeeCredentials([redacted])';
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
// ShopeeCredentials.origin()
//   : shopeeCredentials = "", assert(shopeeCredentials == ""),
// exampleShopeeCredentials = abc;
