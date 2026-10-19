import 'package:json_annotation/json_annotation.dart';
import 'shopee_product_offer_entity.dart';
import 'shopee_page_info_entity.dart';

part 'shopee_product_page_entity.g.dart';

/// One page of product offers; an empty list does not prove an item is sold out.
@JsonSerializable(checked: true, explicitToJson: true)
final class ShopeeProductPageEntity {
  ShopeeProductPageEntity({
    required List<ShopeeProductOfferEntity> nodes,
    required this.pageInfo,
  }) : nodes = List.unmodifiable(nodes);

  final List<ShopeeProductOfferEntity> nodes;
  final ShopeePageInfoEntity pageInfo;

  factory ShopeeProductPageEntity.fromJson(Map<String, dynamic> json) =>
      _$ShopeeProductPageEntityFromJson(json);
  Map<String, dynamic> toJson() => _$ShopeeProductPageEntityToJson(this);
}

/*
 Learn more: https://pub.dev/packages/json_serializable
 Generation online: https://app.quicktype.io/

 Step 1: add properties in follow: https://pub.dev/packages/json_serializable#example
 Step 2: generate code by running
  flutter pub run build_runner build --delete-conflicting-outputs
*/
//Setup Object: https://dart.dev/codelabs/dart-cheatsheet#initializer-lists
//OR | ShopeeProductPageEntity(...).toJson().toMyRealJson();
/// Handle for list data:
/*
   // Old
   static List<ShopeeProductPageEntity>? fromJsonToListTypeJson(dynamic json) =>
   json == null ? null : List<ShopeeProductPageEntity>.from((json as List<Object?>).map((e) => e == null ? null : ShopeeProductPageEntity.fromJson(e as MyJsonMap)),);

   static List<ShopeeProductPageEntity> fromJsonToListTypeString(String data) =>
   List<ShopeeProductPageEntity>.from((json.decode(data) as List<Object?>).map((e) => e == null ? null : ShopeeProductPageEntity.fromJson(e as MyJsonMap)),);
   */
/*copyWith:
   final     :  A a = A(…a, name:  “ten a”)
   no final  :  A a,  a.name = “ten a”*/
/*
  /// copyWith
  ShopeeProductPageEntity copyWith({
      String? example,
      // User? Function()? user,
   }) {
      return ShopeeProductPageEntity(
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
final ShopeeProductPageEnum pricingMode;


bool _paramToJson(ShopeeProductPageEnum paramValue) {
      return paramValue.value;
}
ShopeeProductPageEnum _paramFromJson(bool paramValue) {
      return ShopeeProductPageEnum.getEnumByValue(paramValue);
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
