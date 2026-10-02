import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_oklyn_mobile/core/error/failure.dart';
import 'package:flutter_oklyn_mobile/features/master_product/domain/entities/master_support.dart';
import 'package:flutter_oklyn_mobile/features/master_product/presentation/utils/failure_text.dart';
import 'package:flutter_oklyn_mobile/shared/themes/app_colors.dart';

/// Loads the children of [parentId] (`null` = root). Throw on failure — a
/// thrown [Failure] shows its message, anything else the fallback text.
typedef CategoryBrowse = Future<List<CategoryTreeNode>> Function(int? parentId);

/// Category tree drill-down, one level at a time (R-h) — port of web
/// `presentation/components/CategoryTreeColumns.tsx` (@09208a0).
///
/// **Purpose**: the web shows Finder-style columns side by side; mobile keeps
/// the same column/path state and loading rules but draws only the last
/// column, with a breadcrumb row (`전체 › 대분류 › …`) above it. Tapping a
/// non-leaf appends its children; tapping a leaf fires [onSelectLeaf].
/// **File**: lib/features/master_product/presentation/widgets/category_tree_list.dart
///
/// **Usage**:
/// ```dart
/// CategoryTreeList(
///   browse: _browseTree, // stable method tear-off
///   selectedId: _categoryId,
///   onSelectLeaf: (leaf, path) => setState(() => _categoryId = leaf.id),
/// )
/// CategoryTreeList(browse: _browseTree, expandTo: _ancestorIds, onSelectLeaf: _pick)
/// ```
///
/// ⚠️ Pass [browse] as a stable reference (a method tear-off). A new closure
///    on every parent build reloads the tree and loses the drill-down.
/// ⚠️ [expandTo] = root→…→target ancestor id chain; the columns are rebuilt
///    along it whenever its contents change.
/// ❌ No add-category mode here (management screen only on the web).
class CategoryTreeList extends StatefulWidget {
  final CategoryBrowse browse;
  final void Function(CategoryTreeNode leaf, List<CategoryTreeNode> path)
      onSelectLeaf;
  final int? selectedId;
  final List<int>? expandTo;

  const CategoryTreeList({
    required this.browse,
    required this.onSelectLeaf,
    super.key,
    this.selectedId,
    this.expandTo,
  });

  @override
  State<CategoryTreeList> createState() => _CategoryTreeListState();
}

class _Column {
  final int? parentId;
  final List<CategoryTreeNode> nodes;
  final bool loading;
  final String? error;

  const _Column({
    required this.parentId,
    required this.nodes,
    required this.loading,
    this.error,
  });
}

const String _browseFailed = '카테고리 조회에 실패했습니다.';

String _errorText(Object e) =>
    e is Failure ? failureText(e, _browseFailed) : _browseFailed;

class _CategoryTreeListState extends State<CategoryTreeList> {
  // Initial state = root column loading (spinner before the first browse).
  List<_Column> _columns = const [
    _Column(parentId: null, nodes: [], loading: true),
  ];
  List<CategoryTreeNode> _path = const [];
  // Guards against results of a superseded load (web `alive`).
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CategoryTreeList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.browse != oldWidget.browse ||
        !listEquals(widget.expandTo, oldWidget.expandTo)) {
      _load();
    }
  }

  // Load the root column, or rebuild the columns along [expandTo].
  Future<void> _load() async {
    final seq = ++_loadSeq;
    final expandTo = widget.expandTo;
    if (expandTo != null && expandTo.isNotEmpty) {
      try {
        final cols = <_Column>[];
        final pathNodes = <CategoryTreeNode>[];
        int? parent;
        for (var level = 0; level < expandTo.length; level++) {
          final nodes = await widget.browse(parent);
          cols.add(_Column(parentId: parent, nodes: nodes, loading: false));
          CategoryTreeNode? node;
          for (final n in nodes) {
            if (n.id == expandTo[level]) {
              node = n;
              break;
            }
          }
          if (node == null) {
            break; // chain inconsistent with the current tree
          }
          pathNodes.add(node);
          if (node.leaf) {
            break;
          }
          parent = node.id;
        }
        // If the target is a non-leaf, also show its children column.
        final last = pathNodes.isEmpty ? null : pathNodes.last;
        if (last != null && !last.leaf) {
          final children = await widget.browse(last.id);
          cols.add(_Column(parentId: last.id, nodes: children, loading: false));
        }
        if (mounted && seq == _loadSeq) {
          setState(() {
            _columns = cols.isNotEmpty
                ? cols
                : const [_Column(parentId: null, nodes: [], loading: false)];
            _path = pathNodes;
          });
        }
      } on Object catch (e) {
        if (mounted && seq == _loadSeq) {
          setState(() => _columns = [
                _Column(
                    parentId: null,
                    nodes: const [],
                    loading: false,
                    error: _errorText(e)),
              ]);
        }
      }
      return;
    }
    try {
      final nodes = await widget.browse(null);
      if (mounted && seq == _loadSeq) {
        setState(() => _columns = [
              _Column(parentId: null, nodes: nodes, loading: false),
            ]);
      }
    } on Object catch (e) {
      if (mounted && seq == _loadSeq) {
        setState(() => _columns = [
              _Column(
                  parentId: null,
                  nodes: const [],
                  loading: false,
                  error: _errorText(e)),
            ]);
      }
    }
  }

  Future<void> _handleNodeTap(int col, CategoryTreeNode node) async {
    // Truncate the path/columns to the right of the tapped column.
    final nextPath = [..._path.take(col), node];
    setState(() => _path = nextPath);

    if (node.leaf) {
      setState(() => _columns = _columns.take(col + 1).toList());
      widget.onSelectLeaf(node, nextPath);
      return;
    }

    // Non-leaf: append a loading child column, then replace with the result.
    setState(() => _columns = [
          ..._columns.take(col + 1),
          _Column(parentId: node.id, nodes: const [], loading: true),
        ]);
    try {
      final nodes = await widget.browse(node.id);
      if (!mounted) {
        return;
      }
      setState(() => _columns = [
            ..._columns.take(col + 1),
            _Column(parentId: node.id, nodes: nodes, loading: false),
          ]);
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _columns = [
            ..._columns.take(col + 1),
            _Column(
                parentId: node.id,
                nodes: const [],
                loading: false,
                error: _errorText(e)),
          ]);
    }
  }

  // Breadcrumb `전체` = back to the root column.
  void _goRoot() => setState(() {
        _columns = _columns.take(1).toList();
        _path = const [];
      });

  // Breadcrumb i = show the children of path[i].
  void _goPath(int i) => setState(() {
        _columns = _columns.take(i + 2).toList();
        _path = _path.take(i + 1).toList();
      });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final col = _columns.length - 1;
    final column = _columns[col];
    final crumbStyle = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                style: crumbStyle,
                onPressed: _goRoot,
                child: const Text('전체', style: TextStyle(fontSize: 14)),
              ),
              for (var i = 0; i < _path.length; i++)
                if (!_path[i].leaf) ...[
                  Text('›', style: TextStyle(color: scheme.onSurfaceVariant)),
                  TextButton(
                    style: crumbStyle,
                    onPressed: () => _goPath(i),
                    child: Text(_path[i].name,
                        style: const TextStyle(fontSize: 14)),
                  ),
                ],
            ],
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _buildColumn(context, col, column),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(BuildContext context, int col, _Column column) {
    final scheme = Theme.of(context).colorScheme;
    final error = column.error;
    if (column.loading) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (error != null) {
      return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: scheme.errorContainer,
        child: Text(error, style: TextStyle(fontSize: 12, color: scheme.error)),
      );
    }
    if (column.nodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          col == 0 ? '카테고리가 없습니다.' : '하위 카테고리가 없습니다.',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      );
    }
    final selectedId = widget.selectedId;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 256),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: column.nodes.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: scheme.outlineVariant),
        itemBuilder: (context, index) {
          final node = column.nodes[index];
          final onPath = col < _path.length && _path[col].id == node.id;
          final isSelectedLeaf =
              node.leaf && selectedId != null && node.id == selectedId;
          final background = isSelectedLeaf
              ? AppColors.infoSurface
              : onPath
                  ? scheme.surfaceContainerHighest
                  : null;
          return Material(
            color: background ?? scheme.surface,
            child: InkWell(
              onTap: () => _handleNodeTap(col, node),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        node.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelectedLeaf ? FontWeight.w500 : null,
                          color: isSelectedLeaf
                              ? AppColors.infoForeground
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      node.leaf ? '선택' : '›',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
