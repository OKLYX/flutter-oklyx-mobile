// Which category required-attributes / notice fields are owned by the OPTION,
// not the master — port of web
// `app/dashboard/master-products/[id]/components/optionMetaFields.ts`
// (@09208a0).
// File: lib/features/master_product/presentation/logic/option_meta_fields.dart
//
// Per-unit volume/weight and quantity differ per option, so the master does
// not own them. The predicates split master vs option placement only —
// requiredness comes from the schema `required` flag.
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';

const List<String> _optionFieldTokens = ['수량', '용량', '중량', '무게', '부피'];
final RegExp _hangul = RegExp(r'[가-힣]');

/// Whether [name] contains [token] on a word boundary: the token ends the name
/// or the next char is not Hangul (`대용량식품` excluded, `개당 용량`·`내용량`
/// included).
bool hasBoundaryToken(String name, String token) {
  var idx = name.indexOf(token);
  while (idx != -1) {
    final afterIndex = idx + token.length;
    if (afterIndex >= name.length || !_hangul.hasMatch(name[afterIndex])) {
      return true;
    }
    idx = name.indexOf(token, idx + 1);
  }
  return false;
}

/// A field name names an option-owned physical concept.
bool isOptionField(String name) =>
    _optionFieldTokens.any((t) => hasBoundaryToken(name, t));

/// A category attribute belongs to the option layer.
bool isOptionAttribute(CategoryAttribute a) => isOptionField(a.name);

/// A backend notice is option-owned when its key names a whitelisted concept.
bool isOptionNotice(CategoryNotice notice) => isOptionField(notice.key);

/// Whether this is the "quantity" field the component quantity sum fills.
/// ⚠️ `개당 수량` is a separate attribute and is excluded.
bool isTotalQuantityName(String name) =>
    name.contains('수량') && !name.contains('개당');
