// JSON <-> domain conversion for master_product — the only file in this
// feature that knows JSON keys. Keys = web entity field names (@09208a0).
// When serializing requests, a web `undefined` (omitted key) is a Dart `null`
// and the key is left out. Fields the web sends as explicit `null` are marked.
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/detail_content.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/listing_registration.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_product.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';

typedef Json = Map<String, dynamic>;

// ── Read helpers ──────────────────────────────────────────────────────────
int _int(Object? v) => (v as num).toInt();
int? _intN(Object? v) => v == null ? null : (v as num).toInt();
num _num(Object? v) => v as num;
num? _numN(Object? v) => v as num?;
String _str(Object? v) => v?.toString() ?? '';
String? _strN(Object? v) => v?.toString();
bool _bool(Object? v) => v == true;
bool? _boolN(Object? v) => v as bool?;

Map<String, String> _strMap(Object? v) => v is Map
    ? v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? ''))
    : <String, String>{};

Map<String, String>? _strMapN(Object? v) => v == null ? null : _strMap(v);

List<String> _strList(Object? v) =>
    v is List ? v.map((e) => e.toString()).toList() : <String>[];

List<T> _list<T>(Object? v, T Function(Json) parse) =>
    v is List ? v.map((e) => parse(e as Json)).toList() : <T>[];

// ── master_product.dart ──────────────────────────────────────────────────
MasterComponent masterComponentFromJson(Json j) => MasterComponent(
      productId: _int(j['productId']),
      productName: _str(j['productName']),
      netContent: _strN(j['netContent']),
      netContentUnit: _strN(j['netContentUnit']),
    );

MasterOptionItem masterOptionItemFromJson(Json j) => MasterOptionItem(
      productId: _int(j['productId']),
      productName: _str(j['productName']),
      quantity: _int(j['quantity']),
    );

MasterOption masterOptionFromJson(Json j) => MasterOption(
      id: _int(j['id']),
      name: _str(j['name']),
      items: _list(j['items'], masterOptionItemFromJson),
      deliveryId: _intN(j['deliveryId']),
      packageId: _intN(j['packageId']),
      categoryAttributes: _strMapN(j['categoryAttributes']),
      categoryNotices: _strMapN(j['categoryNotices']),
      marketRegistered: _boolN(j['marketRegistered']),
      stockQuantity: _intN(j['stockQuantity']),
      clampedChannels: _intN(j['clampedChannels']),
    );

MasterProduct masterProductFromJson(Json j) => MasterProduct(
      id: _int(j['id']),
      name: _str(j['name']),
      sourceImageUrl: _strN(j['sourceImageUrl']),
      fieldValues: _strMap(j['fieldValues']),
      defaultDeliveryId: _intN(j['defaultDeliveryId']),
      defaultPackageId: _intN(j['defaultPackageId']),
      components: _list(j['components'], masterComponentFromJson),
      options: _list(j['options'], masterOptionFromJson),
      tags: _strList(j['tags']),
      registrationName: _strN(j['registrationName']),
      optionCheckSuffixEnabled: _boolN(j['optionCheckSuffixEnabled']),
      optionCheckSuffix: _strN(j['optionCheckSuffix']),
      shippingOverride: _strMapN(j['shippingOverride']),
    );

MasterProductPage masterProductPageFromJson(Json j) => MasterProductPage(
      content: _list(j['content'], masterProductFromJson),
      totalElements: _int(j['totalElements']),
      totalPages: _int(j['totalPages']),
      number: _int(j['number']),
      size: _int(j['size']),
    );

MasterByComponents masterByComponentsFromJson(Json j) => MasterByComponents(
      id: _int(j['id']),
      name: _str(j['name']),
      optionCount: _int(j['optionCount']),
    );

MasterByAnyComponent masterByAnyComponentFromJson(Json j) =>
    MasterByAnyComponent(
      id: _int(j['id']),
      name: _str(j['name']),
      components: _list(
        j['components'],
        (c) => MasterComponentRef(
          productId: _int(c['productId']),
          productName: _str(c['productName']),
        ),
      ),
    );

/// Like the web repository `getCategory`: `null` when `categoryId` is absent.
MasterCategory? masterCategoryFromJson(Object? v) {
  if (v is! Map || v['categoryId'] == null) {
    return null;
  }
  return MasterCategory(
    categoryId: _int(v['categoryId']),
    categoryName: _str(v['categoryName']),
  );
}

CategoryAttribute categoryAttributeFromJson(Json j) => CategoryAttribute(
      name: _str(j['name']),
      required: _bool(j['required']),
      inputType: _str(j['inputType']),
      options: _strList(j['options']),
      basicUnit: _strN(j['basicUnit']),
    );

CategoryNotice categoryNoticeFromJson(Json j) => CategoryNotice(
      key: _str(j['key']),
      label: _str(j['label']),
      required: _bool(j['required']),
      groupName: _strN(j['groupName']),
    );

CategoryMeta categoryMetaFromJson(Json j) {
  final values = (j['values'] as Json?) ?? const <String, dynamic>{};
  return CategoryMeta(
    attributes: _list(j['attributes'], categoryAttributeFromJson),
    notices: _list(j['notices'], categoryNoticeFromJson),
    values: CategoryMetaValues(
      attributes: _strMap(values['attributes']),
      notices: _strMap(values['notices']),
      noticeGroup: _strN(values['noticeGroup']),
    ),
  );
}

CategoryMetaSchema categoryMetaSchemaFromJson(Json j) => CategoryMetaSchema(
      attributes: _list(j['attributes'], categoryAttributeFromJson),
      notices: _list(j['notices'], categoryNoticeFromJson),
    );

MatrixCell matrixCellFromJson(Json j) => MatrixCell(
      productListingId: _int(j['productListingId']),
      name: _str(j['name']),
      registrationName: _str(j['registrationName']),
      platformProductId: _strN(j['platformProductId']),
      sellingPrice: _numN(j['sellingPrice']),
      status: _strN(j['status']),
      categoryCode: _strN(j['categoryCode']),
      categoryName: _strN(j['categoryName']),
      usesOwnCategory: _boolN(j['usesOwnCategory']),
      needsMarketSync: _boolN(j['needsMarketSync']),
    );

MatrixRow matrixRowFromJson(Json j) => MatrixRow(
      sellerId: _int(j['sellerId']),
      sellerName: _str(j['sellerName']),
      platform: _str(j['platform']),
      accountId: _int(j['accountId']),
      accountLabel: _str(j['accountLabel']),
      registered: _bool(j['registered']),
      cell: j['cell'] == null ? null : matrixCellFromJson(j['cell'] as Json),
      cells: j['cells'] == null ? null : _list(j['cells'], matrixCellFromJson),
    );

ListingMatrix listingMatrixFromJson(Json j) => ListingMatrix(
      masterId: _int(j['masterId']),
      masterName: _str(j['masterName']),
      rows: _list(j['rows'], matrixRowFromJson),
      masterCategoryName: _strN(j['masterCategoryName']),
    );

ShippingForceApplyResult shippingForceApplyFromJson(Json j) =>
    ShippingForceApplyResult(affectedChannels: _int(j['affectedChannels']));

Json masterOptionRequestItemToJson(MasterOptionRequestItem i) =>
    {'productId': i.productId, 'quantity': i.quantity};

Json masterOptionRequestToJson(MasterOptionRequest r) => {
      'name': r.name,
      'items': r.items.map(masterOptionRequestItemToJson).toList(),
      if (r.deliveryId != null) 'deliveryId': r.deliveryId,
      if (r.packageId != null) 'packageId': r.packageId,
      if (r.categoryAttributes != null)
        'categoryAttributes': r.categoryAttributes,
      if (r.categoryNotices != null) 'categoryNotices': r.categoryNotices,
      if (r.stockQuantity != null) 'stockQuantity': r.stockQuantity,
    };

Json masterProductRequestToJson(MasterProductRequest r) => {
      'name': r.name,
      'componentProductIds': r.componentProductIds,
      if (r.fieldValues != null) 'fieldValues': r.fieldValues,
      if (r.defaultDeliveryId != null) 'defaultDeliveryId': r.defaultDeliveryId,
      if (r.defaultPackageId != null) 'defaultPackageId': r.defaultPackageId,
      if (r.options != null)
        'options': r.options!.map(masterOptionRequestToJson).toList(),
    };

Json masterProductUpdateRequestToJson(MasterProductUpdateRequest r) => {
      if (r.name != null) 'name': r.name,
      if (r.fieldValues != null) 'fieldValues': r.fieldValues,
      if (r.componentProductIds != null)
        'componentProductIds': r.componentProductIds,
      if (r.defaultDeliveryId != null) 'defaultDeliveryId': r.defaultDeliveryId,
      if (r.defaultPackageId != null) 'defaultPackageId': r.defaultPackageId,
    };

Json masterCompositionRequestToJson(MasterCompositionRequest r) => {
      'componentProductIds': r.componentProductIds,
      'options': r.options
          .map(
            (o) => {
              if (o.optionId != null) 'optionId': o.optionId,
              'name': o.name,
              'items': o.items.map(masterOptionRequestItemToJson).toList(),
            },
          )
          .toList(),
    };

Json categoryAttributesRequestToJson(CategoryAttributesRequest r) => {
      'attributes': r.attributes,
      'notices': r.notices,
      // The web sends the notice group key even when it is null.
      'noticeGroup': r.noticeGroup,
    };

// ── listing_registration.dart ────────────────────────────────────────────
OptionPrice optionPriceFromJson(Json j) => OptionPrice(
      optionId: _int(j['optionId']),
      optionName: _strN(j['optionName']),
      sellingPrice: _num(j['sellingPrice']),
      active: _boolN(j['active']),
      onMarket: _boolN(j['onMarket']),
      stockQuantity: _intN(j['stockQuantity']),
      maxStock: _int(j['maxStock']),
      priceSource: _strN(j['priceSource']),
      optionNameSource: _strN(j['optionNameSource']),
      channelOnly: _boolN(j['channelOnly']),
    );

GeneratedProduct generatedProductFromJson(Json j) => GeneratedProduct(
      productListingId: _int(j['productListingId']),
      thumbnailUrl: _strN(j['thumbnailUrl']),
      detailHtml: _strN(j['detailHtml']),
      source: _str(j['source']),
      thumbnailSource: _str(j['thumbnailSource']),
      fieldValues: _strMap(j['fieldValues']),
      tags: _strList(j['tags']),
      optionPrices: _list(j['optionPrices'], optionPriceFromJson),
      shippingOverride: _strMapN(j['shippingOverride']),
      shippingReady: _boolN(j['shippingReady']),
      detailTemplateId: _intN(j['detailTemplateId']),
    );

ChannelAddResult channelAddResultFromJson(Json j) => ChannelAddResult(
      productListingId: _int(j['productListingId']),
      status: _str(j['status']),
      generated: generatedProductFromJson(j['generated'] as Json),
      categoryWarning: _strN(j['categoryWarning']),
    );

BatchChannelAddResult batchChannelAddResultFromJson(Json j) =>
    BatchChannelAddResult(
      requested: _int(j['requested']),
      succeeded: _int(j['succeeded']),
      failed: _int(j['failed']),
      results: _list(
        j['results'],
        (r) => BatchChannelAddItem(
          sellerId: _int(r['sellerId']),
          platform: _str(r['platform']),
          success: _bool(r['success']),
          productListingId: _intN(r['productListingId']),
          errorMessage: _strN(r['errorMessage']),
        ),
      ),
    );

ListingRegisterResult listingRegisterResultFromJson(Json j) =>
    ListingRegisterResult(
      productListingId: _int(j['productListingId']),
      status: _str(j['status']),
      platformProductId: _strN(j['platformProductId']),
    );

ListingStatusOption listingStatusOptionFromJson(Json j) => ListingStatusOption(
      optionId: _int(j['optionId']),
      approvalStatus: _str(j['approvalStatus']),
      platformOptionId: _strN(j['platformOptionId']),
    );

ListingStatusResult listingStatusResultFromJson(Json j) => ListingStatusResult(
      productListingId: _int(j['productListingId']),
      status: _str(j['status']),
      options: _list(j['options'], listingStatusOptionFromJson),
      reviewNote: _strN(j['reviewNote']),
      reviewNoteState: _strN(j['reviewNoteState']),
    );

PropagateResult propagateResultFromJson(Json j) => PropagateResult(
      propagated: _int(j['propagated']),
      skipped: _int(j['skipped']),
      failed: _int(j['failed']),
    );

ChannelSyncPreview channelSyncPreviewFromJson(Json j) {
  final t = j['totals'] as Json;
  return ChannelSyncPreview(
    inSync: _bool(j['inSync']),
    totals: ChannelSyncTotals(
      affectedChannels: _int(t['affectedChannels']),
      missingOptions: _int(t['missingOptions']),
      channelOnlyOptions: _int(t['channelOnlyOptions']),
      quantityMismatch: _int(t['quantityMismatch']),
    ),
    channels: _list(
      j['channels'],
      (c) => ChannelSyncChannel(
        listingId: _int(c['listingId']),
        sellerName: _str(c['sellerName']),
        platform: _str(c['platform']),
        onMarket: _bool(c['onMarket']),
        missingOptions: _strList(c['missingOptions']),
        channelOnlyOptions: _strList(c['channelOnlyOptions']),
        marketChannelOnlyOptions: _strList(c['marketChannelOnlyOptions']),
        quantityMismatchOptions: _strList(c['quantityMismatchOptions']),
      ),
    ),
  );
}

ListingOptionSummary listingOptionSummaryFromJson(Json j) =>
    ListingOptionSummary(
      optionId: _int(j['optionId']),
      optionName: _str(j['optionName']),
      sellingPrice: _num(j['sellingPrice']),
      active: _bool(j['active']),
      approvalStatus: _str(j['approvalStatus']),
      stockQuantity: _intN(j['stockQuantity']),
      maxStock: _int(j['maxStock']),
      priceSource: _strN(j['priceSource']),
      optionNameSource: _strN(j['optionNameSource']),
      channelOnly: _boolN(j['channelOnly']),
      platformOptionId: _strN(j['platformOptionId']),
      masterOptionId: _intN(j['masterOptionId']),
    );

ListingOptions listingOptionsFromJson(Json j) => ListingOptions(
      productListingId: _int(j['productListingId']),
      status: _str(j['status']),
      options: _list(j['options'], listingOptionSummaryFromJson),
      needsResync: _boolN(j['needsResync']),
      registrationName: _strN(j['registrationName']),
    );

MasterChannelOptions masterChannelOptionsFromJson(Json j) =>
    MasterChannelOptions(
      masterId: _int(j['masterId']),
      cells: _list(
        j['cells'],
        (c) => ChannelOptionCell(
          productListingId: _int(c['productListingId']),
          platformProductId: _strN(c['platformProductId']),
          status: _str(c['status']),
          options: _list(c['options'], listingOptionSummaryFromJson),
        ),
      ),
    );

ChannelPriceUpdateResult channelPriceUpdateResultFromJson(Json j) =>
    ChannelPriceUpdateResult(
      listing: listingOptionsFromJson(j['listing'] as Json),
      pushed: _int(j['pushed']),
      skipped: _strList(j['skipped']),
      failed: _list(
        j['failed'],
        (f) => ChannelPriceFailure(
          optionName: _str(f['optionName']),
          message: _str(f['message']),
        ),
      ),
    );

ImportPreview importPreviewFromJson(Json j) => ImportPreview(
      productName: _str(j['productName']),
      status: _str(j['status']),
      categoryCode: _str(j['categoryCode']),
      categoryMatched: _bool(j['categoryMatched']),
      categoryWarning: _strN(j['categoryWarning']),
      channelTags: _strList(j['channelTags']),
      reusesExistingListing: _bool(j['reusesExistingListing']),
      components: _list(
        j['components'],
        (c) => ImportPreviewComponent(
          productId: _int(c['productId']),
          brand: _strN(c['brand']),
          productName: _str(c['productName']),
        ),
      ),
      options: _list(
        j['options'],
        (o) => ImportPreviewOption(
          itemName: _str(o['itemName']),
          vendorItemId: _strN(o['vendorItemId']),
          sellerProductItemId: _strN(o['sellerProductItemId']),
          salePrice: _num(o['salePrice']),
          stockQuantity: _intN(o['stockQuantity']),
        ),
      ),
    );

Json importOptionSpecToJson(ImportOptionSpec s) => {
      // The web sends the key even when null (option not approved yet).
      'vendorItemId': s.vendorItemId,
      'itemName': s.itemName,
      'masterOptionName': s.masterOptionName,
      'components': s.components
          .map((c) => {'productId': c.productId, 'quantity': c.quantity})
          .toList(),
    };

DetachedListing detachedListingFromJson(Json j) => DetachedListing(
      productListingId: _int(j['productListingId']),
      platformProductId: _str(j['platformProductId']),
      name: _str(j['name']),
      status: _str(j['status']),
    );

MarketOption marketOptionFromJson(Json j) => MarketOption(
      itemName: _strN(j['itemName']),
      vendorItemId: _strN(j['vendorItemId']),
      sellerProductItemId: _strN(j['sellerProductItemId']),
      salePrice: _numN(j['salePrice']),
      linkedOptionId: _intN(j['linkedOptionId']),
      linkedOptionName: _strN(j['linkedOptionName']),
    );

ApplyOptionNamesResult applyOptionNamesResultFromJson(Json j) =>
    ApplyOptionNamesResult(
      updatedCells: _int(j['updatedCells']),
      updatedOptions: _int(j['updatedOptions']),
      warnings: _strList(j['warnings']),
    );

ChannelApplyOptionNamesResult channelApplyOptionNamesResultFromJson(Json j) =>
    ChannelApplyOptionNamesResult(
      updatedOptions: _int(j['updatedOptions']),
      skippedAwaitingId: _strList(j['skippedAwaitingId']),
    );

MasterFromChannelPreview masterFromChannelPreviewFromJson(Json j) =>
    MasterFromChannelPreview(
      productName: _strN(j['productName']),
      suggestedMasterName: _strN(j['suggestedMasterName']),
      status: _str(j['status']),
      categoryCode: _strN(j['categoryCode']),
      suggestedCategoryId: _intN(j['suggestedCategoryId']),
      suggestedCategoryName: _strN(j['suggestedCategoryName']),
      categoryResolved: _bool(j['categoryResolved']),
      options: _list(
        j['options'],
        (o) => MasterFromChannelOption(
          itemName: _str(o['itemName']),
          platformOptionId: _strN(o['platformOptionId']),
          sellerProductItemId: _strN(o['sellerProductItemId']),
          salePrice: _num(o['salePrice']),
          stockQuantity: _intN(o['stockQuantity']),
          attributes: _strMap(o['attributes']),
        ),
      ),
      commonAttributes: _strMap(j['commonAttributes']),
      notices: _strMap(j['notices']),
      noticeGroup: _strN(j['noticeGroup']),
      reusesExistingListing: _bool(j['reusesExistingListing']),
    );

// ── detail_content.dart ──────────────────────────────────────────────────
DetailBlock detailBlockFromJson(Json j) => DetailBlock(
      type: _str(j['type']),
      bind: _strN(j['bind']),
      src: _strN(j['src']),
      defaultValue: _strN(j['defaultValue']),
      widthPercent: _intN(j['widthPercent']),
      align: _strN(j['align']),
      heightPx: _intN(j['heightPx']),
      textStyle: _strMapN(j['textStyle']),
      processingPresetId: _intN(j['processingPresetId']),
    );

DetailTemplate detailTemplateFromJson(Json j) => DetailTemplate(
      id: _int(j['id']),
      name: _str(j['name']),
      blocks: _list(j['blocks'], detailBlockFromJson),
      active: _bool(j['active']),
      isDefault: _bool(j['isDefault']),
      blockCount: _intN(j['blockCount']),
      imageProcessingPresetId: _intN(j['imageProcessingPresetId']),
    );

MasterPoolImage masterPoolImageFromJson(Json j) => MasterPoolImage(
      id: _int(j['id']),
      imageUrl: _str(j['imageUrl']),
      sortOrder: _int(j['sortOrder']),
      assignedZones: _strList(j['assignedZones']),
      isSource: _bool(j['isSource']),
      productImageId: _intN(j['productImageId']),
    );

// ── master_support.dart ──────────────────────────────────────────────────
StandardCategory standardCategoryFromJson(Json j) => StandardCategory(
      id: _int(j['id']),
      name: _str(j['name']),
      platform: _str(j['platform']),
      platformCategoryId: _str(j['platformCategoryId']),
      parentId: _intN(j['parentId']),
    );

CategoryTreeNode categoryTreeNodeFromJson(Json j) => CategoryTreeNode(
      id: _int(j['id']),
      name: _str(j['name']),
      leaf: _bool(j['leaf']),
    );

ProductGalleryImage productGalleryImageFromJson(Json j) => ProductGalleryImage(
      id: _int(j['id']),
      productId: _int(j['productId']),
      sortOrder: _int(j['sortOrder']),
      imageUrl: _str(j['imageUrl']),
    );

ThumbnailTemplateSummary thumbnailTemplateSummaryFromJson(Json j) =>
    ThumbnailTemplateSummary(
      id: _int(j['id']),
      name: _str(j['name']),
      isDefault: _bool(j['isDefault']),
      fields: _list(
        j['fields'],
        (f) => TemplateField(
          key: _str(f['key']),
          label: _str(f['label']),
          defaultValue: _str(f['defaultValue']),
        ),
      ),
    );

DetailImageGroup detailImageGroupFromJson(Json j) => DetailImageGroup(
      id: _int(j['id']),
      code: _str(j['code']),
      name: _str(j['name']),
      sortOrder: _int(j['sortOrder']),
      templateCount: _int(j['templateCount']),
      imageCount: _int(j['imageCount']),
      usedByTemplateNames: _strList(j['usedByTemplateNames']),
    );

CategoryMapping categoryMappingFromJson(Json j) => CategoryMapping(
      platform: _str(j['platform']),
      platformCategoryId: _str(j['platformCategoryId']),
      platformCategoryName: _strN(j['platformCategoryName']),
    );

MasterBox masterBoxFromJson(Json j) => MasterBox(
      id: _int(j['id']),
      type: _str(j['type']),
      cost: _num(j['cost']),
      isDefault: _bool(j['isDefault']),
    );

OutboundPlace outboundPlaceFromJson(Json j) =>
    OutboundPlace(code: _str(j['code']), name: _str(j['name']));

ReturnCenter returnCenterFromJson(Json j) => ReturnCenter(
      code: _str(j['code']),
      name: _str(j['name']),
      chargeName: _strN(j['chargeName']),
      contactNumber: _strN(j['contactNumber']),
      zipCode: _strN(j['zipCode']),
      address: _strN(j['address']),
      addressDetail: _strN(j['addressDetail']),
      returnCharge: _numN(j['returnCharge']),
      deliveryChargeOnReturn: _numN(j['deliveryChargeOnReturn']),
    );

ShippingSettings shippingSettingsFromJson(Json j) => ShippingSettings(
      marketplaceAccountId: _intN(j['marketplaceAccountId']),
      outboundShippingPlaceCode: _strN(j['outboundShippingPlaceCode']),
      returnCenterCode: _strN(j['returnCenterCode']),
      returnChargeName: _strN(j['returnChargeName']),
      returnContactNumber: _strN(j['returnContactNumber']),
      returnZipCode: _strN(j['returnZipCode']),
      returnAddress: _strN(j['returnAddress']),
      returnAddressDetail: _strN(j['returnAddressDetail']),
      returnCharge: _numN(j['returnCharge']),
      deliveryChargeOnReturn: _numN(j['deliveryChargeOnReturn']),
      deliveryMethod: _strN(j['deliveryMethod']),
      deliveryCompanyCode: _strN(j['deliveryCompanyCode']),
      deliveryChargeType: _strN(j['deliveryChargeType']),
      deliveryCharge: _numN(j['deliveryCharge']),
      freeShipOverAmount: _numN(j['freeShipOverAmount']),
      remoteAreaDeliverable: _strN(j['remoteAreaDeliverable']),
      unionDeliveryType: _strN(j['unionDeliveryType']),
      extraInfoMessage: _strN(j['extraInfoMessage']),
    );

/// Web `ShippingConfigRequest` — all 17 keys are sent, nulls included (same as
/// the web).
Json shippingConfigRequestToJson(ShippingSettings s) => {
      'outboundShippingPlaceCode': s.outboundShippingPlaceCode,
      'returnCenterCode': s.returnCenterCode,
      'returnChargeName': s.returnChargeName,
      'returnContactNumber': s.returnContactNumber,
      'returnZipCode': s.returnZipCode,
      'returnAddress': s.returnAddress,
      'returnAddressDetail': s.returnAddressDetail,
      'returnCharge': s.returnCharge,
      'deliveryChargeOnReturn': s.deliveryChargeOnReturn,
      'deliveryMethod': s.deliveryMethod,
      'deliveryCompanyCode': s.deliveryCompanyCode,
      'deliveryChargeType': s.deliveryChargeType,
      'deliveryCharge': s.deliveryCharge,
      'freeShipOverAmount': s.freeShipOverAmount,
      'remoteAreaDeliverable': s.remoteAreaDeliverable,
      'unionDeliveryType': s.unionDeliveryType,
      'extraInfoMessage': s.extraInfoMessage,
    };
