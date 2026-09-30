// Shipping override conversion — ports of web `domain/entities/ShippingEntity.ts` (@09208a0).
// Key order = web `ShippingOverride` field order. The 4 numeric keys are strings when saved, numbers when loaded.
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';

/// Web `EMPTY_SHIPPING_OVERRIDE`.
const ShippingSettings kEmptyShippingOverride = ShippingSettings();

/// Web `ShippingOverride` keys, 17 in fixed order.
const List<String> kShippingOverrideKeys = [
  'outboundShippingPlaceCode',
  'returnCenterCode',
  'returnChargeName',
  'returnContactNumber',
  'returnZipCode',
  'returnAddress',
  'returnAddressDetail',
  'returnCharge',
  'deliveryChargeOnReturn',
  'deliveryMethod',
  'deliveryCompanyCode',
  'deliveryChargeType',
  'deliveryCharge',
  'freeShipOverAmount',
  'remoteAreaDeliverable',
  'unionDeliveryType',
  'extraInfoMessage',
];

/// Web `NUMERIC_OVERRIDE_KEYS`.
const List<String> kNumericOverrideKeys = [
  'returnCharge',
  'deliveryChargeOnReturn',
  'deliveryCharge',
  'freeShipOverAmount',
];

/// Web `PLACE_OVERRIDE_KEYS`.
const List<String> kPlaceOverrideKeys = [
  'outboundShippingPlaceCode',
  'returnCenterCode',
  'returnChargeName',
  'returnContactNumber',
  'returnZipCode',
  'returnAddress',
  'returnAddressDetail',
];

/// Value of one key — `num?` for the 4 numeric keys, `String?` otherwise.
Object? shippingFieldOf(ShippingSettings s, String key) => switch (key) {
      'outboundShippingPlaceCode' => s.outboundShippingPlaceCode,
      'returnCenterCode' => s.returnCenterCode,
      'returnChargeName' => s.returnChargeName,
      'returnContactNumber' => s.returnContactNumber,
      'returnZipCode' => s.returnZipCode,
      'returnAddress' => s.returnAddress,
      'returnAddressDetail' => s.returnAddressDetail,
      'returnCharge' => s.returnCharge,
      'deliveryChargeOnReturn' => s.deliveryChargeOnReturn,
      'deliveryMethod' => s.deliveryMethod,
      'deliveryCompanyCode' => s.deliveryCompanyCode,
      'deliveryChargeType' => s.deliveryChargeType,
      'deliveryCharge' => s.deliveryCharge,
      'freeShipOverAmount' => s.freeShipOverAmount,
      'remoteAreaDeliverable' => s.remoteAreaDeliverable,
      'unionDeliveryType' => s.unionDeliveryType,
      'extraInfoMessage' => s.extraInfoMessage,
      _ => null,
    };

/// Web `{ ...value, [key]: next }` — a copy with one key changed (including clearing with `null`).
ShippingSettings withShippingField(
  ShippingSettings s,
  String key,
  Object? value,
) {
  Object? pick(String k) => k == key ? value : shippingFieldOf(s, k);
  return ShippingSettings(
    marketplaceAccountId: s.marketplaceAccountId,
    outboundShippingPlaceCode: pick('outboundShippingPlaceCode') as String?,
    returnCenterCode: pick('returnCenterCode') as String?,
    returnChargeName: pick('returnChargeName') as String?,
    returnContactNumber: pick('returnContactNumber') as String?,
    returnZipCode: pick('returnZipCode') as String?,
    returnAddress: pick('returnAddress') as String?,
    returnAddressDetail: pick('returnAddressDetail') as String?,
    returnCharge: pick('returnCharge') as num?,
    deliveryChargeOnReturn: pick('deliveryChargeOnReturn') as num?,
    deliveryMethod: pick('deliveryMethod') as String?,
    deliveryCompanyCode: pick('deliveryCompanyCode') as String?,
    deliveryChargeType: pick('deliveryChargeType') as String?,
    deliveryCharge: pick('deliveryCharge') as num?,
    freeShipOverAmount: pick('freeShipOverAmount') as num?,
    remoteAreaDeliverable: pick('remoteAreaDeliverable') as String?,
    unionDeliveryType: pick('unionDeliveryType') as String?,
    extraInfoMessage: pick('extraInfoMessage') as String?,
  );
}

bool _isBlank(Object? v) =>
    v == null || (v is String && v.trim().isEmpty);

/// Web `String(value)` — integers are printed without a decimal point.
String _stringOf(Object v) =>
    v is num && v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// Web `overrideToMap` — empty/null values are dropped (= inherited), numbers become strings.
Map<String, String> overrideToMap(ShippingSettings o) {
  final map = <String, String>{};
  for (final key in kShippingOverrideKeys) {
    final value = shippingFieldOf(o, key);
    if (_isBlank(value)) {
      continue;
    }
    map[key] = _stringOf(value!);
  }
  return map;
}

/// Web `mapToOverride` — unknown keys are dropped, numeric keys become numbers (empty or non-numeric = null).
ShippingSettings mapToOverride(Map<String, String>? map) {
  var result = kEmptyShippingOverride;
  if (map == null) {
    return result;
  }
  for (final entry in map.entries) {
    if (!kShippingOverrideKeys.contains(entry.key)) {
      continue;
    }
    final raw = entry.value;
    if (kNumericOverrideKeys.contains(entry.key)) {
      result = withShippingField(result, entry.key, num.tryParse(raw));
    } else {
      result = withShippingField(result, entry.key, raw == '' ? null : raw);
    }
  }
  return result;
}

/// Web `configToOverride` — the same values without the account id.
ShippingSettings configToOverride(ShippingSettings? c) {
  if (c == null) {
    return kEmptyShippingOverride;
  }
  var result = kEmptyShippingOverride;
  for (final key in kShippingOverrideKeys) {
    result = withShippingField(result, key, shippingFieldOf(c, key));
  }
  return result;
}

/// Web `mergePreset` — per field, own when non-empty, otherwise base.
ShippingSettings mergePreset(ShippingSettings own, ShippingSettings base) {
  var result = base;
  for (final key in kShippingOverrideKeys) {
    final value = shippingFieldOf(own, key);
    if (!_isBlank(value)) {
      result = withShippingField(result, key, value);
    }
  }
  return result;
}

/// Web `diffOverride` — only non-empty fields that differ from the baseline are saved.
Map<String, String> diffOverride(ShippingSettings form, ShippingSettings base) {
  final out = <String, String>{};
  for (final key in kShippingOverrideKeys) {
    final f = shippingFieldOf(form, key);
    final b = shippingFieldOf(base, key);
    final fs = _isBlank(f) ? '' : _stringOf(f!);
    final bs = _isBlank(b) ? '' : _stringOf(b!);
    if (fs != '' && fs != bs) {
      out[key] = fs;
    }
  }
  return out;
}

/// Web `channelDivergesFromMaster`.
bool channelDivergesFromMaster(
  Map<String, String>? channelOverride,
  Map<String, String> masterMap,
) {
  if (channelOverride == null) {
    return false;
  }
  return channelOverride.keys.any(
    (key) =>
        !kPlaceOverrideKeys.contains(key) &&
        channelOverride[key] != masterMap[key],
  );
}
