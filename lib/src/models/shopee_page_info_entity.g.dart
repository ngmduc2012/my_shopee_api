// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopee_page_info_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopeePageInfoEntity _$ShopeePageInfoEntityFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ShopeePageInfoEntity', json, ($checkedConvert) {
  final val = ShopeePageInfoEntity(
    page: $checkedConvert('page', (v) => (v as num).toInt()),
    limit: $checkedConvert('limit', (v) => (v as num).toInt()),
    hasNextPage: $checkedConvert('hasNextPage', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$ShopeePageInfoEntityToJson(
  ShopeePageInfoEntity instance,
) => <String, dynamic>{
  'page': instance.page,
  'limit': instance.limit,
  'hasNextPage': instance.hasNextPage,
};
