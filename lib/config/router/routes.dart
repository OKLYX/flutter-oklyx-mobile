class Routes {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String dashboard = 'dashboard';
  static const String listToShop = 'listToShop';
  static const String notification = 'notification';
  static const String productRegister = 'productRegister';
  static const String productSearch = 'productSearch';
  static const String productDetail = 'productDetail';
  static const String stockInOut = 'stockInOut';
  static const String stockSearch = 'stockSearch';
  static const String stockOutbound = 'stockOutbound';
  static const String userRegister = 'userRegister';
  static const String userManage = 'userManage';
  static const String userEdit = 'userEdit';
  static const String packageSearch = 'packageSearch';
  static const String packageDetail = 'packageDetail';
  static const String categoryList = 'categoryList';
  static const String categoryCreate = 'categoryCreate';
  static const String carrierRate = 'carrierRate';
  static const String carrierRateDetail = 'carrierRateDetail';
  static const String carrier = 'carrier';
  static const String seller = 'seller';
  static const String sellerCreate = 'sellerCreate';
  static const String sellerDetail = 'sellerDetail';
  static const String commissionRate = 'commissionRate';
  static const String commissionRateDetail = 'commissionRateDetail';
  static const String salesProducts = 'salesProducts';
  static const String salesProductsDetail = 'salesProductsDetail';
  static const String salesProductsEdit = 'salesProductsEdit';
  static const String shipmentManagement = 'shipmentManagement';
  static const String orderHistory = 'orderHistory';
  static const String orderHistoryDetail = 'orderHistoryDetail';
  static const String claimList = 'claimList';
  static const String claimDetail = 'claimDetail';
  static const String inquiryList = 'inquiryList';
  static const String inquiryDetail = 'inquiryDetail';
  static const String shippingLabelPreview = 'shippingLabelPreview';
  static const String shippingLabelPreviewInternal =
      'shippingLabelPreviewInternal';
  static const String reservedShipment = 'reservedShipment';
  static const String orderSettings = 'orderSettings';
  static const String notFound = 'notFound';
  // Six master product screens + ported windows (FEATURE_2609_80). Distinct path prefixes keep
  // the `:id` route from swallowing other routes (independent of registration order).
  static const String masterProducts = 'masterProducts';
  static const String masterProductNew = 'masterProductNew';
  static const String masterProductFromMarket = 'masterProductFromMarket';
  static const String masterProductDetail = 'masterProductDetail';
  static const String masterProductComposition = 'masterProductComposition';
  static const String masterProductDetailEdit = 'masterProductDetailEdit';
  static const String masterChannelFieldValues = 'masterChannelFieldValues';
  static const String masterChannelStock = 'masterChannelStock';
  static const String masterChannelPrice = 'masterChannelPrice';
  static const String masterChannelOptionName = 'masterChannelOptionName';
  static const String masterChannelShipping = 'masterChannelShipping';
  static const String masterMarketProductAdd = 'masterMarketProductAdd';
  static const String masterShippingConfig = 'masterShippingConfig';

  static const String splashPath = '/';
  static const String loginPath = '/login';
  static const String dashboardPath = '/dashboard';
  static const String listToShopPath = '/list-to-shop';
  static const String notificationPath = '/notification';
  static const String productRegisterPath = '/product-register';
  static const String productSearchPath = '/product-search';
  static const String productDetailPath = '/product-detail/:productId';
  static const String stockInOutPath = '/stock/in-out';
  static const String stockSearchPath = '/stock/search';
  static const String stockOutboundPath = '/stock/outbound';
  static const String userRegisterPath = '/users/register';
  static const String userManagePath = '/users/manage';
  static const String userEditPath = '/users/edit';
  static const String packageSearchPath = '/costs/package/search';
  static const String packageDetailPath = '/costs/package/:id';
  static const String categoryListPath = '/categories';
  static const String categoryCreatePath = '/categories/create';
  static const String categoryDetail = 'categoryDetail';
  static const String categoryDetailPath = '/categories/:id';
  static const String carrierRatePath = '/costs/carrier/search';
  static const String carrierRateDetailPath = '/costs/carrier/:id';
  static const String carrierPath = '/costs/carrier-company/search';
  static const String sellerPath = '/costs/seller/search';
  static const String sellerCreatePath = '/costs/seller/search/create';
  static const String sellerDetailPath = '/costs/seller/:id';
  static const String commissionRatePath = '/costs/commission/search';
  static const String commissionRateDetailPath = '/costs/commission/:id';
  static const String salesProductsPath = '/sales-products';
  static const String salesProductsDetailPath = '/sales-products/detail/:id';
  static const String salesProductsEditPath = '/sales-products/edit/:id';
  static const String shipmentManagementPath = '/orders/shipment';
  static const String orderHistoryPath = '/orders/history';
  static const String orderHistoryDetailPath = '/orders/history/detail';
  static const String claimListPath = '/orders/claims';
  static const String claimDetailPath = '/orders/claims/detail';
  static const String inquiryListPath = '/orders/inquiries';
  static const String inquiryDetailPath = '/orders/inquiries/detail';
  static const String shippingLabelPreviewPath = '/shipping-label/preview';
  static const String shippingLabelPreviewInternalPath =
      '/shipping-label/preview-internal';
  static const String reservedShipmentPath = '/shipping-label/reserved';
  static const String orderSettingsPath = '/orders/settings';
  static const String notFoundPath = '/404';
  static const String masterProductsPath = '/master-products';
  static const String masterProductNewPath = '/master-products-new';
  static const String masterProductFromMarketPath = '/master-products-from-market';
  static const String masterProductDetailPath = '/master-product/:id';
  static const String masterProductCompositionPath =
      '/master-product/:id/composition';
  static const String masterProductDetailEditPath =
      '/master-product/:id/detail/:listingId';
  static const String masterChannelFieldValuesPath =
      '/master-product-tools/channel-field-values';
  static const String masterChannelStockPath =
      '/master-product-tools/channel-stock';
  static const String masterChannelPricePath =
      '/master-product-tools/channel-price';
  static const String masterChannelOptionNamePath =
      '/master-product-tools/channel-option-name';
  static const String masterChannelShippingPath =
      '/master-product-tools/channel-shipping';
  static const String masterMarketProductAddPath =
      '/master-product-tools/market-product-add';
  static const String masterShippingConfigPath =
      '/master-product-tools/shipping-config';

  static String salesProductsDetailRoute(int id) =>
      '/sales-products/detail/$id';
  static String salesProductsEditRoute(int id) => '/sales-products/edit/$id';
}
