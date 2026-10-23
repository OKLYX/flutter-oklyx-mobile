import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/domain/entities/dashboard.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_card_data_bloc.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/bloc/dashboard_card_data_state.dart';
import 'package:flutter_oklyn_mobile/features/dashboard/presentation/utils/dashboard_grid_spec.dart';
import 'package:flutter_oklyn_mobile/shared/widgets/app_card.dart';

/// Frame of the dashboard cards (FEATURE_2610_29 / D16 · D21): card, title
/// row, body.
///
/// - Outside edit mode a tap opens the card's screen (`context.go`).
/// - In edit mode the card does not navigate and its controls are inert; ✕
///   removes it.
///
/// ❌ No size or padding knob — the size comes from the grid (D10).
class DashboardCardFrame extends StatelessWidget {
  final DashboardCardType type;
  final bool editing;
  final VoidCallback onRemove;

  /// Controls at the right end of the title row (period · 「전체 | 채널」).
  final List<Widget> actions;
  final Widget child;

  const DashboardCardFrame({
    required this.type,
    required this.editing,
    required this.onRemove,
    required this.child,
    super.key,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final spec = specOf(type);
    final scheme = Theme.of(context).colorScheme;
    return AppCard.row(
      onTap: editing ? null : () => context.go(spec.route),
      child: SizedBox(
        height: MobileGrid.rowHeight - 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    spec.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final action in actions)
                  IgnorePointer(
                    ignoring: editing,
                    child: Opacity(opacity: editing ? 0.5 : 1, child: action),
                  ),
                if (editing)
                  InkWell(
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(Icons.close, size: 18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(child: IgnorePointer(ignoring: editing, child: child)),
          ],
        ),
      ),
    );
  }
}

/// Loading / failure of a card body; [builder] draws the loaded data.
class DashboardCardBody<T> extends StatelessWidget {
  final Widget Function(BuildContext context, T data) builder;

  const DashboardCardBody({required this.builder, super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DashboardCardDataBloc<T>, DashboardCardDataState<T>>(
        builder: (context, state) {
          final data = state.data;
          if (state.loading) {
            return const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          if (data == null) {
            return Text(
              state.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return builder(context, data);
        },
      );
}

/// Period selector in a card's title row (D22 · D23).
class DashboardPeriodDropdown extends StatelessWidget {
  final DashboardCardType type;
  final DashboardPeriod value;
  final ValueChanged<DashboardPeriod> onChanged;

  const DashboardPeriodDropdown({
    required this.type,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) => DropdownButton<DashboardPeriod>(
        value: value,
        isDense: true,
        underline: const SizedBox.shrink(),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        items: [
          for (final period in specOf(type).periods)
            DropdownMenuItem(
              value: period,
              child: Text(kPeriodLabels[period]!),
            ),
        ],
        onChanged: (period) {
          if (period != null) {
            onChanged(period);
          }
        },
      );
}

/// Big number with a small unit (counts of the number cards).
class DashboardCount extends StatelessWidget {
  final String value;
  final String unit;

  const DashboardCount({required this.value, required this.unit, super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: ' $unit',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// A small label over a number (the numbers of C5 · C6 · C8).
class DashboardFigure extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const DashboardFigure({
    required this.label,
    required this.value,
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      );
}
