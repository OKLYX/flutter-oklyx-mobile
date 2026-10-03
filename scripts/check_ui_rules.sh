#!/usr/bin/env bash
# UI rule check of the mobile app (FEATURE_2610_02 · T9).
#
# Plain text search over lib/ — no Flutter, no packages. Fails (exit 1) when a
# page draws by hand something that has a shared part:
#   1. confirm dialog        -> showAppConfirmDialog (app_confirm_dialog.dart)
#   2. bottom sheet          -> showAppSheet (app_sheet.dart)
#   3. copied private parts  -> AppBusyLabel / AppErrorBox / showAppConfirmDialog
#                               / AppFormField / AppDetailField
#   4. bottom nav height     -> AppPageBody (app_page_body.dart)
#   5. input border          -> theme (app_theme.dart)
#   6. old bottom snack bar  -> showSuccessToast / showErrorToast /
#                               showInputNoticeToast / showNoticeToast
#   7. card drawn by hand    -> AppCard (app_card.dart)
#
# Comment lines (// and ///) are ignored.
# An exception is a file path written after the pattern of its rule, with the
# reason in the comment above the rule. Do not add a file there to make a new
# page pass — use the shared part.
set -u
cd "$(dirname "$0")/.."

fail=0

# check <label> <what to use instead> <pattern> [allowed file]...
check() {
  local label="$1" hint="$2" pattern="$3"
  shift 3
  local hits allowed
  hits=$(grep -rnE --include='*.dart' "$pattern" lib |
    grep -vE '^[^:]+:[0-9]+:[[:space:]]*//' || true)
  for allowed in "$@"; do
    hits=$(printf '%s\n' "$hits" | grep -v "^${allowed}:" || true)
  done
  if [ -n "$hits" ]; then
    printf '✗ %s\n%s\n  → %s\n\n' "$label" "$hits" "$hint"
    fail=1
  fi
}

# 1. Allowed: the shared dialog itself + popups that are not confirm dialogs
#    (input form, details, progress, notice, navigation choice — D108).
check '화면에서 직접 그린 확인창 (AlertDialog)' \
  'showAppConfirmDialog 를 쓴다 (lib/shared/widgets/app_confirm_dialog.dart)' \
  '(^|[^A-Za-z_])AlertDialog\(' \
  lib/shared/widgets/app_confirm_dialog.dart \
  lib/features/carrier/presentation/dialogs/carrier_input_dialog.dart \
  lib/features/carrier/presentation/dialogs/platform_code_input_dialog.dart \
  lib/features/claim/presentation/widgets/claim_action_sheet.dart \
  lib/features/marketplace_account/presentation/dialogs/channel_details_dialog.dart \
  lib/features/marketplace_account/presentation/dialogs/channel_form_dialog.dart \
  lib/features/order/presentation/widgets/sync_progress_dialog.dart \
  lib/features/product_listing/presentation/pages/product_listing_register_page.dart \
  lib/features/shipping_label/presentation/widgets/reserved_shipment_row_tile.dart \
  lib/shared/pages/user_register_page.dart

# 2. Allowed: the shared sheet itself.
check '화면에서 직접 연 아래 창 (showModalBottomSheet)' \
  'showAppSheet 를 쓴다 (lib/shared/widgets/app_sheet.dart)' \
  'showModalBottomSheet' \
  lib/shared/widgets/app_sheet.dart

# 3. No exception.
check '공용 부품의 복사본 (private class)' \
  'AppBusyLabel · AppErrorBox · showAppConfirmDialog · AppFormField · AppDetailField 를 쓴다' \
  'class (_BusyLabel|_ErrorRetry|_DeleteConfirmationDialog|_FormField|_DetailField) '

# 4. Allowed: the page body frame itself + the drawer (its logout button sits
#    above the nav bar; the drawer layout is out of scope — T12).
check '화면에서 하단 메뉴 높이를 직접 더한 곳 (kBottomNavigationBarHeight)' \
  'AppPageBody 를 쓴다. 아래 고정 버튼은 AppPageBody.navBarInset(context)' \
  'kBottomNavigationBarHeight' \
  lib/shared/widgets/app_page_body.dart \
  lib/shared/widgets/app_drawer.dart

# 5. Allowed: the theme.
check '입력칸에 테두리를 직접 적은 곳 (OutlineInputBorder)' \
  '지운다 — 테두리는 테마가 준다 (lib/shared/themes/app_theme.dart)' \
  'OutlineInputBorder\(' \
  lib/shared/themes/app_theme.dart

# 6. Allowed: the toast itself + the batch result notice (summary line + one
#    line per failed item — D31).
check '옛 하단 알림 (SnackBar)' \
  'showSuccessToast · showErrorToast · showInputNoticeToast · showNoticeToast 를 쓴다 (lib/shared/widgets/result_toast.dart)' \
  '(^|[^A-Za-z_])SnackBar\(' \
  lib/shared/widgets/result_toast.dart \
  lib/features/order/presentation/pages/shipment_management_page.dart

# 7. Allowed: the shared card itself + rows inside a section that draw their
#    own card (D107). The card shape switch is read in AppCard only
#    (FEATURE_2610_03 · D140).
check '화면에서 직접 그린 카드 (Card()' \
  'AppCard 를 쓴다 (lib/shared/widgets/app_card.dart)' \
  '(^|[^A-Za-z_.])Card\(' \
  lib/shared/widgets/app_card.dart \
  lib/features/carrier/presentation/widgets/platform_code_section.dart \
  lib/features/marketplace_account/presentation/widgets/seller_channel_section.dart \
  lib/features/master_product/presentation/widgets/channel_option_table.dart \
  lib/features/master_product/presentation/widgets/listing_detail_panel.dart \
  lib/features/master_product/presentation/widgets/market_source_card.dart \
  lib/features/master_product/presentation/widgets/master_composition_form.dart \
  lib/features/master_product/presentation/widgets/master_create_form.dart \
  lib/features/order/presentation/pages/order_detail_page.dart \
  lib/features/shipping_label/presentation/widgets/stored_invoice_section.dart

if [ "$fail" -eq 0 ]; then
  echo '✓ UI 규칙 위반 없음'
fi
exit "$fail"
