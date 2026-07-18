import 'package:flutter/material.dart';

import '../../core/theme/tide_colors.dart';
import '../../domain/entities/note.dart';
import 'prefix_text.dart';

class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.index,
    required this.onChanged,
    required this.onRescue,
    this.busy = false,
    this.rescueEnabled = true,
  });

  final Note note;
  final int index;
  final bool busy;
  final bool rescueEnabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onRescue;

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  late final FocusNode _focusNode;
  TextEditingController? _controller;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.note.content != widget.note.content) {
      _controller?.text = widget.note.content;
    }
  }

  void _beginEditing() {
    if (widget.busy) return;
    _controller = TextEditingController(text: widget.note.content);
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus || !_editing) return;
    final controller = _controller;
    if (controller != null) widget.onChanged(controller.text);
    setState(() => _editing = false);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final factor = (widget.index / 18).clamp(0.0, 1.0);
    final strong = scheme.onSurface;
    final muted = Theme.of(context).brightness == Brightness.dark
        ? TideColors.darkMuted
        : TideColors.lightMuted;
    final foreground = Color.lerp(strong, muted, factor)!;

    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: _editing
            ? TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Edit note',
                ),
                onChanged: widget.onChanged,
              )
            : DefaultTextStyle.merge(
                style: TextStyle(color: foreground),
                child: PrefixText(
                  content: widget.note.content,
                  index: widget.index,
                ),
              ),
      ),
    );

    final interactive = InkWell(
      onTap: widget.busy ? null : _beginEditing,
      borderRadius: BorderRadius.circular(18),
      child: child,
    );

    if (widget.busy || !widget.rescueEnabled) {
      return KeyedSubtree(key: ValueKey(widget.note.id), child: interactive);
    }

    return Semantics(
      label: 'Rescue note',
      button: true,
      child: Dismissible(
        key: ValueKey(widget.note.id),
        direction: DismissDirection.startToEnd,
        background: const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 24),
            child: Icon(Icons.wb_sunny_outlined),
          ),
        ),
        confirmDismiss: (_) async {
          widget.onRescue();
          return false;
        },
        child: interactive,
      ),
    );
  }
}
