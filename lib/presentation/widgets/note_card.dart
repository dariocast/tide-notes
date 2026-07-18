import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/tide_colors.dart';
import '../../core/utils/note_metadata_formatter.dart';
import '../../domain/entities/note.dart';
import 'prefix_text.dart';

void defaultTideHaptic() {
  if (defaultTargetPlatform == TargetPlatform.macOS) return;
  HapticFeedback.lightImpact();
}

DateTime defaultNoteNow() => DateTime.now();

class NoteCard extends StatefulWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.index,
    required this.onChanged,
    required this.onRescue,
    this.busy = false,
    this.rescueEnabled = true,
    this.haptic = defaultTideHaptic,
    this.now = defaultNoteNow,
  });

  final Note note;
  final int index;
  final bool busy;
  final bool rescueEnabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onRescue;
  final VoidCallback haptic;
  final DateTime Function() now;

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
    final rescue = rescueMetadata(widget.note.rescueCount);
    final metadata = [
      relativeSurfacedAge(widget.note.surfacedAt, widget.now()),
      MaterialLocalizations.of(
        context,
      ).formatMediumDate(widget.note.surfacedAt),
      if (rescue.isNotEmpty) rescue,
    ].join(' • ');

    final child = AnimatedContainer(
      key: const ValueKey('note-row'),
      width: double.infinity,
      duration: MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 80)
          : const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_editing)
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                labelText: 'Edit note',
              ),
              onChanged: widget.onChanged,
            )
          else
            DefaultTextStyle.merge(
              style: TextStyle(color: foreground),
              child: PrefixText(
                content: widget.note.content,
                index: widget.index,
              ),
            ),
          const SizedBox(height: 7),
          Text(
            metadata,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.outline,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    final interactive = InkWell(
      onTap: widget.busy ? null : _beginEditing,
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
        background: ColoredBox(
          color: scheme.primaryContainer.withValues(alpha: 0.55),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 24),
              child: Icon(Icons.arrow_upward_rounded),
            ),
          ),
        ),
        confirmDismiss: (_) async {
          widget.haptic();
          widget.onRescue();
          return false;
        },
        child: interactive,
      ),
    );
  }
}
