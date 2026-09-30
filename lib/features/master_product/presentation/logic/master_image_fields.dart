import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_image_pool.dart';

/// Field list derivation for [MasterImagePool] — port of web
/// `app/dashboard/master-products/components/masterImageFields.ts` (@09208a0).
/// **File**: lib/features/master_product/presentation/logic/master_image_fields.dart
///
/// - [fields] = cover photo ([kSourceZone], always first) + every catalog
///   group (key = code, label = name, catalog sortOrder).
/// - [fieldFilters] = filter-only sets (cover photo + one per template).
///   Render order is always owned by [fields].
/// - [requiredZoneKeys] = the default template only (create form gate).
class MasterImageFields {
  final List<ImageField> fields;
  final List<ImageFieldFilter> fieldFilters;
  final List<String> requiredZoneKeys;

  const MasterImageFields({
    required this.fields,
    required this.fieldFilters,
    required this.requiredZoneKeys,
  });
}

List<String> _zoneKeysOf(DetailTemplate t) => t.blocks
    .where((b) => b.type == 'imageZone' && (b.bind ?? '').isNotEmpty)
    .map((b) => b.bind!)
    .toList();

/// Derives the pool fields from the detail image group catalog and the
/// detail templates (S14 · S1).
///
/// A failure of either call is non-blocking → cover photo only (web `catch`).
/// ⚠️ Not pure (server calls) — call it from `initState` and keep the result
///    in State.
/// ⚠️ Callers = create page · master detail only. The detail editor's
///    structured-data tab derives from a single template instead.
Future<MasterImageFields> deriveMasterImageFields() async {
  final useCase = getIt<MasterProductUseCase>();
  // Cover photo is a template-independent filter, always first.
  final filters = <ImageFieldFilter>[
    const ImageFieldFilter(label: '대표사진', keys: [kSourceZone], kind: 'cover'),
  ];
  // Both calls run in parallel (web `Promise.all`).
  final groupsFuture = useCase.listDetailImageGroups();
  final templatesFuture = useCase.listDetailTemplates();
  await Future.wait([groupsFuture, templatesFuture]);
  final groups = (await groupsFuture).fold((_) => null, (r) => r);
  final templates = (await templatesFuture).fold((_) => null, (r) => r);
  if (groups == null || templates == null) {
    return MasterImageFields(
      fields: const [ImageField(key: kSourceZone, label: '대표사진')],
      fieldFilters: filters,
      requiredZoneKeys: const [],
    );
  }
  for (final t in templates) {
    final zoneKeys = _zoneKeysOf(t);
    if (zoneKeys.isNotEmpty) {
      filters.add(ImageFieldFilter(
        label: t.name + (t.isDefault ? ' (기본)' : ''),
        keys: zoneKeys,
        kind: 'detail',
      ));
    }
  }
  final defaults = templates.where((t) => t.isDefault);
  return MasterImageFields(
    // Order is the catalog's sortOrder (the backend sorts) — never re-sort
    // by template.
    fields: [
      const ImageField(key: kSourceZone, label: '대표사진'),
      ...groups.map((g) => ImageField(key: g.code, label: g.name)),
    ],
    fieldFilters: filters,
    requiredZoneKeys: defaults.isEmpty ? const [] : _zoneKeysOf(defaults.first),
  );
}
