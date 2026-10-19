// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopee_product_offer_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShopeeProductOfferEntity _$ShopeeProductOfferEntityFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ShopeeProductOfferEntity', json, ($checkedConvert) {
  final val = ShopeeProductOfferEntity(
    itemId: $checkedConvert('itemId', (v) => (v as num).toInt()),
    shopId: $checkedConvert('shopId', (v) => (v as num).toInt()),
    productName: $checkedConvert('productName', (v) => v as String),
    imageUrl: $checkedConvert('imageUrl', (v) => v as String?),
    priceMin: $checkedConvert('priceMin', (v) => v as String?),
    priceMax: $checkedConvert('priceMax', (v) => v as String?),
    shopName: $checkedConvert('shopName', (v) => v as String?),
    productLink: $checkedConvert('productLink', (v) => v as String?),
    offerLink: $checkedConvert('offerLink', (v) => v as String?),
    commissionRate: $checkedConvert('commissionRate', (v) => v as String?),
    sales: $checkedConvert('sales', (v) => (v as num?)?.toInt()),
    ratingStar: $checkedConvert('ratingStar', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$ShopeeProductOfferEntityToJson(
  ShopeeProductOfferEntity instance,
) => <String, dynamic>{
  'itemId': instance.itemId,
  'shopId': instance.shopId,
  'productName': instance.productName,
  if (instance.imageUrl case final value?) 'imageUrl': value,
  if (instance.priceMin case final value?) 'priceMin': value,
  if (instance.priceMax case final value?) 'priceMax': value,
  if (instance.shopName case final value?) 'shopName': value,
  if (instance.productLink case final value?) 'productLink': value,
  if (instance.offerLink case final value?) 'offerLink': value,
  if (instance.commissionRate case final value?) 'commissionRate': value,
  if (instance.sales case final value?) 'sales': value,
  if (instance.ratingStar case final value?) 'ratingStar': value,
};
