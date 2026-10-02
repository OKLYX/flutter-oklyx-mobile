import 'package:flutter/material.dart';

/// Tag chip input shared by the master tag pool and channel raw tags — port
/// of web `presentation/components/TagChipsInput.tsx` (@09208a0).
///
/// **Purpose**: the parent owns [tags] and receives every change through
/// [onChanged] (controlled). Only the typed draft lives here.
/// **File**: lib/features/master_product/presentation/widgets/tag_chips_input.dart
///
/// **Behavior** (same as the web):
/// - a comma / newline in the text → everything before the last delimiter
///   becomes tags, the rest stays in the field (IME-safe, paste-safe)
/// - keyboard done (Enter) or losing focus → the draft becomes a tag
/// - blank and duplicate (exact match) tokens are skipped
/// - each chip's delete icon removes that chip
///
/// **Usage**:
/// ```dart
/// TagChipsInput(tags: _tags, onChanged: (next) => setState(() => _tags = next))
/// TagChipsInput(tags: _tags, onChanged: _setTags, disabled: _saving)
/// TagChipsInput(tags: _tags, onChanged: _setTags, placeholder: '태그 입력')
/// ```
///
/// ⚠️ Backspace on an empty field does not remove the last chip on mobile
///    (no standard key event for it on phone keyboards) — use the chip's
///    delete icon.
/// ❌ Do not keep a second copy of [tags] in the parent's widget tree — this
///    widget never stores the list itself.
class TagChipsInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final bool disabled;
  final String? placeholder;

  const TagChipsInput({
    required this.tags,
    required this.onChanged,
    super.key,
    this.disabled = false,
    this.placeholder,
  });

  @override
  State<TagChipsInput> createState() => _TagChipsInputState();
}

class _TagChipsInputState extends State<TagChipsInput> {
  final TextEditingController _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  // Split on commas (and newlines); order-preserving dedup against the
  // existing tags and within the batch itself.
  void _addTokens(String raw) {
    final next = [...widget.tags];
    for (final token in raw.split(RegExp(r'[,\n]'))) {
      final value = token.trim();
      if (value != '' && !next.contains(value)) {
        next.add(value);
      }
    }
    if (next.length != widget.tags.length) {
      widget.onChanged(next);
    }
  }

  void _commit() {
    _addTokens(_draft.text);
    _draft.clear();
  }

  void _removeAt(int index) {
    final next = [...widget.tags]..removeAt(index);
    widget.onChanged(next);
  }

  // Web `handleChange` — the delimiter only appears after the IME finalizes
  // the composition, so there is no leftover composing char.
  void _handleChange(String value) {
    if (value.contains(',') || value.contains('\n')) {
      final lastBreak = value.lastIndexOf(',') > value.lastIndexOf('\n')
          ? value.lastIndexOf(',')
          : value.lastIndexOf('\n');
      _addTokens(value.substring(0, lastBreak));
      final rest = value.substring(lastBreak + 1);
      _draft.value = TextEditingValue(
        text: rest,
        selection: TextSelection.collapsed(offset: rest.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < widget.tags.length; i++)
              InputChip(
                key: ValueKey('${widget.tags[i]}-$i'),
                label:
                    Text(widget.tags[i], style: const TextStyle(fontSize: 14)),
                isEnabled: !widget.disabled,
                visualDensity: VisualDensity.compact,
                onDeleted: widget.disabled ? null : () => _removeAt(i),
              ),
            SizedBox(
              width: constraints.maxWidth < 160 ? constraints.maxWidth : 160,
              child: Focus(
                onFocusChange: (focused) {
                  if (!focused) {
                    _commit();
                  }
                },
                child: TextField(
                  controller: _draft,
                  enabled: !widget.disabled,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    hintText: widget.placeholder ?? '태그 입력 후 Enter',
                  ),
                  onChanged: _handleChange,
                  onSubmitted: (_) => _commit(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
