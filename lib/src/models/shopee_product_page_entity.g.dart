// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopee_product_page_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopeeProductPageEntity _$ShopeeProductPageEntityFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ShopeeProductPageEntity', json, ($checkedConvert) {
  final val = ShopeeProductPageEntity(
    nodes: $checkedConvert(
      'nodes',
      (v) => (v as List<dynamic>)
          .map(
            (e) => ShopeeProductOfferEntity.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    pageInfo: $checkedConvert(
      'pageInfo',
      (v) => ShopeePageInfoEntity.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$ShopeeProductPageEntityToJson(
  ShopeeProductPageEntity instance,
) => <String, dynamic>{
  'nodes': instance.nodes.map((e) => e.toJson()).toList(),
  'pageInfo': instance.pageInfo.toJson(),
};
