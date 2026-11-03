import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_oklyn_mobile/core/di/service_locator.dart';
import 'package:flutter_oklyn_mobile/features/package/domain/entities/package.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_busy_label.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_form_field.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_sheet.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_state_views.dart';
import '../bloc/box_change_cubit.dart';

/// Opens the 「박스 변경」 sheet and returns the applied box, or `null` when
/// it was closed (drag down · tap outside · back · [취소]).
///
/// [parcelId] `null` = the box being packed (pick only, no server call —
/// FEATURE_2611_06 / D22) · set = a packed parcel whose box changes on the
/// server (D19). [selectedPackageId] = the box picked when the sheet opens.
Future<Package?> showBoxChangeSheet(
  BuildContext context, {
  required int? parcelId,
  required int? selectedPackageId,
}) =>
    showAppSheet<Package>(
      context,
      builder: (sheetContext) => BlocProvider(
        create: (_) => getIt<BoxChangeCubit>()
          ..start(parcelId: parcelId, selectedPackageId: selectedPackageId),
        child: const BoxChangeSheet(),
      ),
    );

/// The 「박스 변경」 sheet (FEATURE_2611_06 / D16 · D20) — the app copy of the
/// web `BoxChangeModal`.
///
/// **Purpose**: one sheet shared by three places — the box being packed
/// ([박스 변경] on the 「포장 작업」 screen), a 「오늘 완료」 row, and
/// [상자 변경] on a 「포장 완료」 card of the 「포장 이력」 screen. It changes to
/// another registered box, picks the shared unregistered recycled box, or
/// registers a new box and applies it at once.
/// **File**: lib/features/packing/presentation/widgets/box_change_sheet.dart
///
/// **Usage**:
/// ```dart
/// // A packed parcel — the server changes its box.
/// final box = await showBoxChangeSheet(context,
///     parcelId: entry.parcelId, selectedPackageId: entry.boxPackageId);
///
/// // The box being packed — only hands the box back.
/// final box = await showBoxChangeSheet(context,
///     parcelId: null, selectedPackageId: state.selectedBoxId);
/// if (box != null) bloc.add(PackingBoxSelected(box.id));
/// ```
///
/// ⚠️ Open it with [showBoxChangeSheet] only — it provides the
///    [BoxChangeCubit] (a new one for every open, the box list is loaded
///    again each time).
/// ⚠️ A refused change keeps the sheet open with the server text inside.
/// ❌ Do not look up or create the shared unregistered recycled box anywhere
///    else — [BoxChangeCubit] is the only place.
/// ❌ Do not copy this sheet into a page.
class BoxChangeSheet extends StatefulWidget {
  const BoxChangeSheet({super.key});

  @override
  State<BoxChangeSheet> createState() => _BoxChangeSheetState();
}

class _BoxChangeSheetState extends State<BoxChangeSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _width = TextEditingController();
  final TextEditingController _length = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _cost = TextEditingController();

  static const TextInputType _numberKeyboard =
      TextInputType.numberWithOptions(decimal: true);

  @override
  void dispose() {
    _name.dispose();
    _width.dispose();
    _length.dispose();
    _height.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _ignore(String _) {}

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<BoxChangeCubit, BoxChangeState>(
        listenWhen: (previous, current) =>
            previous.applied == null && current.applied != null,
        listener: (context, state) => Navigator.of(context).pop(state.applied),
        builder: (context, state) {
          final cubit = context.read<BoxChangeCubit>();
          final textTheme = Theme.of(context).textTheme;
          final locked = state.busy || state.loading;
          final listed = state.listed;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('박스 변경', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('재활용 상자 사용'),
                value: state.recycled,
                onChanged: locked
                    ? null
                    : (value) => cubit.toggleRecycled(value: value ?? false),
              ),
              if (state.loading)
                const AppLoading()
              else ...[
                if (state.recycled)
                  ListTile(
                    title: const Text(kUnregisteredRecycledBoxType),
                    subtitle: const Text('어떤 상자인지 모를 때'),
                    selected: state.unregistered,
                    onTap: locked ? null : cubit.pickUnregistered,
                  ),
                for (final box in listed)
                  ListTile(
                    title: Text(box.type),
                    subtitle: Text('${box.sizeLabel} · ${box.boxKind.label}'),
                    selected: !state.unregistered && state.pickedId == box.id,
                    onTap: locked ? null : () => cubit.pick(box.id),
                  ),
                if (listed.isEmpty && !state.recycled)
                  const Text('등록된 상자가 없습니다. 아래에서 새 상자를 등록하세요.'),
              ],
              const Divider(height: 32),
              Text(
                state.recycled ? '새 상자 등록 (재활용 상자)' : '새 상자 등록 (구매 상자)',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              AppFormField('상자 이름', _name, _ignore),
              AppFormField('가로(cm)', _width, _ignore,
                  keyboardType: _numberKeyboard),
              AppFormField('세로(cm)', _length, _ignore,
                  keyboardType: _numberKeyboard),
              AppFormField('높이(cm)', _height, _ignore,
                  keyboardType: _numberKeyboard),
              AppFormField(
                '비용(원)',
                _cost,
                _ignore,
                keyboardType: _numberKeyboard,
                helperText: state.recycled ? '재활용 상자는 비워 두면 0원입니다' : null,
              ),
              OutlinedButton(
                onPressed: locked
                    ? null
                    : () => cubit.createAndApply(
                          type: _name.text,
                          width: _width.text,
                          length: _length.text,
                          height: _height.text,
                          cost: _cost.text,
                        ),
                child: const Text('등록하고 이 상자로 변경'),
              ),
              if (state.error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  state.error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        locked ? null : () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: locked ? null : cubit.apply,
                    child: state.busy
                        ? const AppBusyLabel('이 상자로 변경')
                        : const Text('이 상자로 변경'),
                  ),
                ],
              ),
            ],
          );
        },
      );
}
