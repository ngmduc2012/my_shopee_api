import 'package:json_annotation/json_annotation.dart';

part 'shopee_product_offer_entity.g.dart';

/// A product offer returned by productOfferV2.
/// Monetary amounts stay as strings, preserving the provider's decimal values.
@JsonSerializable(checked: true, explicitToJson: true, includeIfNull: false)
final class ShopeeProductOfferEntity {
  const ShopeeProductOfferEntity({
    required this.itemId,
    required this.shopId,
    required this.productName,
    this.imageUrl,
    this.priceMin,
    this.priceMax,
    this.shopName,
    this.productLink,
    this.offerLink,
    this.commissionRate,
    this.sales,
    this.ratingStar,
  });

  final int itemId;
  final int shopId;
  final String productName;
  final String? imageUrl;
  final String? priceMin;
  final String? priceMax;
  final String? shopName;
  final String? productLink;
  final String? offerLink;
  final String? commissionRate;
  final int? sales;
  final String? ratingStar;

  factory ShopeeProductOfferEntity.fromJson(Map<String, dynamic> json) =>
      _$ShopeeProductOfferEntityFromJson(json);
  Map<String, dynamic> toJson() => _$ShopeeProductOfferEntityToJson(this);
}

/*
 Learn more: https://pub.dev/packages/json_serializable
 Generation online: https://app.quicktype.io/

 Step 1: add properties in follow: https://pub.dev/packages/json_serializable#example
 Step 2: generate code by running
  flutter pub run build_runner build --delete-conflicting-outputs
*/
//Setup Object: https://dart.dev/codelabs/dart-cheatsheet#initializer-lists
//OR | ShopeeProductOfferEntity(...).toJson().toMyRealJson();
/// Handle for list data:
/*
   // Old
   static List<ShopeeProductOfferEntity>? fromJsonToListTypeJson(dynamic json) =>
   json == null ? null : List<ShopeeProductOfferEntity>.from((json as List<Object?>).map((e) => e == null ? null : ShopeeProductOfferEntity.fromJson(e as MyJsonMap)),);

   static List<ShopeeProductOfferEntity> fromJsonToListTypeString(String data) =>
   List<ShopeeProductOfferEntity>.from((json.decode(data) as List<Object?>).map((e) => e == null ? null : ShopeeProductOfferEntity.fromJson(e as MyJsonMap)),);
   */
/*copyWith:
   final     :  A a = A(…a, name:  “ten a”)
   no final  :  A a,  a.name = “ten a”*/
/*
  /// copyWith
  ShopeeProductOfferEntity copyWith({
      String? example,
      // User? Function()? user,
   }) {
      return ShopeeProductOfferEntity(
         example: example ?? this.example,
         // user: user != null ? user() : this.user,
      );
   }
   */
/*
Custom: Dành cho enum không phải thuộc tính String, int, null để lưu trữ

@JsonKey(
      toJson: _paramToJson,
      fromJson: _paramFromJson
)
final ShopeeProductOfferEnum pricingMode;


bool _paramToJson(ShopeeProductOfferEnum paramValue) {
      return paramValue.value;
}
ShopeeProductOfferEnum _paramFromJson(bool paramValue) {
      return ShopeeProductOfferEnum.getEnumByValue(paramValue);
}

TimeOfDay
@JsonKey(
      toJson: myTimeOfDayToJson,
      fromJson: myJsonToTimeOfDay,
)
required TimeOfDay timeLimitStart,

Locale
@JsonKey(
      toJson: myLocaleToJson,
      fromJson: myJsonToLocale
)
required Locale language,

Duration
@JsonKey(
      fromJson: myDurationFromJson,
      toJson: myDurationToJson,
)
final Duration timeDifference;

*/
