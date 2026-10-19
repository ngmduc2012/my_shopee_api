import 'package:json_annotation/json_annotation.dart';

part 'shopee_page_info_entity.g.dart';

/// Pagination metadata returned by Shopee's product offer query.
@JsonSerializable(checked: true)
final class ShopeePageInfoEntity {
  const ShopeePageInfoEntity({
    required this.page,
    required this.limit,
    required this.hasNextPage,
  });

  final int page;
  final int limit;
  final bool hasNextPage;

  factory ShopeePageInfoEntity.fromJson(Map<String, dynamic> json) =>
      _$ShopeePageInfoEntityFromJson(json);
  Map<String, dynamic> toJson() => _$ShopeePageInfoEntityToJson(this);
}

/*
 Learn more: https://pub.dev/packages/json_serializable
 Generation online: https://app.quicktype.io/

 Step 1: add properties in follow: https://pub.dev/packages/json_serializable#example
 Step 2: generate code by running
  flutter pub run build_runner build --delete-conflicting-outputs
*/
//Setup Object: https://dart.dev/codelabs/dart-cheatsheet#initializer-lists
//OR | ShopeePageInfoEntity(...).toJson().toMyRealJson();
/// Handle for list data:
/*
   // Old
   static List<ShopeePageInfoEntity>? fromJsonToListTypeJson(dynamic json) =>
   json == null ? null : List<ShopeePageInfoEntity>.from((json as List<Object?>).map((e) => e == null ? null : ShopeePageInfoEntity.fromJson(e as MyJsonMap)),);

   static List<ShopeePageInfoEntity> fromJsonToListTypeString(String data) =>
   List<ShopeePageInfoEntity>.from((json.decode(data) as List<Object?>).map((e) => e == null ? null : ShopeePageInfoEntity.fromJson(e as MyJsonMap)),);
   */
/*copyWith:
   final     :  A a = A(…a, name:  “ten a”)
   no final  :  A a,  a.name = “ten a”*/
/*
  /// copyWith
  ShopeePageInfoEntity copyWith({
      String? example,
      // User? Function()? user,
   }) {
      return ShopeePageInfoEntity(
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
final ShopeePageInfoEnum pricingMode;


bool _paramToJson(ShopeePageInfoEnum paramValue) {
      return paramValue.value;
}
ShopeePageInfoEnum _paramFromJson(bool paramValue) {
      return ShopeePageInfoEnum.getEnumByValue(paramValue);
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
