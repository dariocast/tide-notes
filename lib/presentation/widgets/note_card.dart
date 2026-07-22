import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
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
  bool _hovered = false;

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
    final g = tideColorsOf(context);
    final compact = sizeClassOf(context) == GSizeClass.compact;
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
      duration: context.motion.duration(GMotion.color),
      curve: GMotion.settle,
      decoration: BoxDecoration(
        color: _hovered
            ? g.accentSubtle.withValues(alpha: GDecor.hoverAlpha)
            : null,
        border: Border(
          bottom: BorderSide(color: g.lineSubtle, width: GDecor.hairline),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s4,
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s4,
      ),
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
                contentPadding: EdgeInsets.zero,
                isDense: true,
                labelText: 'Edit note',
              ),
              onChanged: widget.onChanged,
            )
          else
            PrefixText(content: widget.note.content, index: widget.index),
          const SizedBox(height: GSpace.s2),
          Text(metadata, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );

    final interactive = FocusRing(
      child: MouseRegion(
        cursor: widget.busy
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: InkWell(onTap: widget.busy ? null : _beginEditing, child: child),
      ),
    );

    if (widget.busy || !widget.rescueEnabled) {
      return KeyedSubtree(key: ValueKey(widget.note.id), child: interactive);
    }

    return Semantics(
      label: 'Rescue note',
      hint: widget.note.content,
      button: true,
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Rescue note'): widget.onRescue,
      },
      child: Dismissible(
        key: ValueKey(widget.note.id),
        direction: DismissDirection.startToEnd,
        background: DecoratedBox(
          decoration: BoxDecoration(color: g.rescueSoft),
          child: Padding(
            padding: EdgeInsets.only(left: compact ? GSpace.s4 : GSpace.s6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                Icons.arrow_upward_rounded,
                color: g.rescue,
                size: 24,
              ),
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
