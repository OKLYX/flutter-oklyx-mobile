import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/usecases/master_product_usecase.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/widgets/master_image_pool.dart';

/// Field list derivation for [MasterImagePool] — port of web
/// `app/dashboard/master-products/components/masterImageFields.ts` (@09208a0,
/// plus the thumbnail template groups of FEATURE_2610_33 02).
/// **File**: lib/features/master_product/presentation/logic/master_image_fields.dart
///
/// - [fields] = cover photo ([kSourceZone], always first, single) + one group
///   per thumbnail template (key = the server's `imageGroupKey`, label =
///   「썸네일 · {name}」 + 「 (기본)」 for the default, template list order,
///   single) + every catalog group (key = code, label = name, catalog
///   sortOrder) — FEATURE_2610_33 D15.
/// - [fieldFilters] = filter-only sets (cover photo + one per thumbnail
///   template, kind `cover` · one per detail template with a bound image
///   zone, kind `detail`). Render order is always owned by [fields].
/// - [requiredZoneKeys] = the default detail template only (create form
///   gate).
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

/// Derives the pool fields from the detail image group catalog, the detail
/// templates and the thumbnail templates (S14 · S1 · FEATURE_2610_33 D15).
///
/// A failure of any of the three calls is non-blocking → cover photo only (web
/// `catch`). Inactive thumbnail templates are listed too (the server list
/// returns all of them).
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
  // The three calls run in parallel (web `Promise.all`).
  final groupsFuture = useCase.listDetailImageGroups();
  final templatesFuture = useCase.listDetailTemplates();
  final thumbnailTemplatesFuture = useCase.listThumbnailTemplates();
  await Future.wait([groupsFuture, templatesFuture, thumbnailTemplatesFuture]);
  final groups = (await groupsFuture).fold((_) => null, (r) => r);
  final templates = (await templatesFuture).fold((_) => null, (r) => r);
  final thumbnailTemplates =
      (await thumbnailTemplatesFuture).fold((_) => null, (r) => r);
  if (groups == null || templates == null || thumbnailTemplates == null) {
    return MasterImageFields(
      fields: const [ImageField(key: kSourceZone, label: '대표사진', single: true)],
      fieldFilters: filters,
      requiredZoneKeys: const [],
    );
  }
  for (final t in thumbnailTemplates) {
    filters.add(ImageFieldFilter(
      label: t.name + (t.isDefault ? ' (기본)' : ''),
      keys: [t.imageGroupKey],
      kind: 'cover',
    ));
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
    // Order: cover photo → thumbnail template groups (server list order) →
    // detail groups (catalog sortOrder, the backend sorts) — never re-sort by
    // template.
    fields: [
      const ImageField(key: kSourceZone, label: '대표사진', single: true),
      ...thumbnailTemplates.map((t) => ImageField(
            key: t.imageGroupKey,
            label: '썸네일 · ${t.name}${t.isDefault ? ' (기본)' : ''}',
            single: true,
          )),
      ...groups.map((g) => ImageField(key: g.code, label: g.name)),
    ],
    fieldFilters: filters,
    requiredZoneKeys: defaults.isEmpty ? const [] : _zoneKeysOf(defaults.first),
  );
}
