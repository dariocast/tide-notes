import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../design/tide_icons.dart';
import '../../design/tide_markdown.dart';
import '../../core/utils/note_metadata_formatter.dart';
import '../../domain/entities/note.dart';
import '../../l10n/tide_localizations.dart';
import 'prefix_text.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    this.onUndo,
    this.busy = false,
    this.rescueEnabled = true,
    this.haptic = defaultTideHaptic,
    this.now = defaultNoteNow,
    this.onEditingChanged,
  });

  final Note note;
  final int index;
  final bool busy;
  final bool rescueEnabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onRescue;
  final VoidCallback? onUndo;
  final VoidCallback haptic;
  final DateTime Function() now;
  final ValueChanged<bool>? onEditingChanged;

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
    widget.onEditingChanged?.call(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus || !_editing) return;
    final controller = _controller;
    if (controller != null) widget.onChanged(controller.text);
    setState(() => _editing = false);
    widget.onEditingChanged?.call(false);
  }

  @override
  void dispose() {
    if (_editing) {
      final onEditingChanged = widget.onEditingChanged;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onEditingChanged?.call(false);
      });
    }
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = tideColorsOf(context);
    final l10n = TideLocalizations.of(context);
    final compact = sizeClassOf(context) == GSizeClass.compact;
    final rescue = rescueMetadata(widget.note.rescueCount);
    final metadata = [
      l10n.relativeSurfacedAge(widget.note.surfacedAt, widget.now()),
      MaterialLocalizations.of(
        context,
      ).formatMediumDate(widget.note.surfacedAt),
      if (rescue.isNotEmpty) rescue,
    ].join(' • ');
    final lines = widget.note.content.split('\n');
    final markdownBody = lines.length > 1 ? lines.skip(1).join('\n') : null;

    final child = AnimatedContainer(
      key: const ValueKey('note-row'),
      width: double.infinity,
      duration: context.motion.duration(GMotion.color),
      curve: GMotion.settle,
      decoration: BoxDecoration(
        color: _hovered
            ? g.accentSubtle.withValues(alpha: GDecor.hoverAlpha)
            : null,
      ),
      padding: EdgeInsets.fromLTRB(
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s2,
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_editing)
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      labelText: l10n.editNote,
                    ),
                    onTapOutside: (_) => _focusNode.unfocus(),
                    onChanged: widget.onChanged,
                  )
                else ...[
                  PrefixText(content: widget.note.content, index: widget.index),
                  if (markdownBody != null)
                    Padding(
                      padding: const EdgeInsets.only(top: GSpace.s1),
                      child: MarkdownBody(
                        data: markdownBody,
                        styleSheet: tideMarkdownStyleSheet(context),
                        shrinkWrap: true,
                      ),
                    ),
                ],
                const SizedBox(height: GSpace.s1),
                Text(metadata, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (!_editing && widget.onUndo != null)
            IconButton(
              onPressed: widget.busy ? null : widget.onUndo,
              tooltip: l10n.undoRescue,
              icon: const FaIcon(TideIcons.undo, size: 18),
            )
          else if (_editing && widget.rescueEnabled)
            TextFieldTapRegion(
              child: IconButton(
                onPressed: widget.busy ? null : widget.onRescue,
                tooltip: l10n.rescueNote,
                icon: const FaIcon(TideIcons.surface, size: 18),
              ),
            ),
        ],
      ),
    );

    final rowInteraction = MouseRegion(
      cursor: widget.busy ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(onTap: widget.busy ? null : _beginEditing, child: child),
    );
    final interactive = _editing
        ? rowInteraction
        : FocusRing(child: rowInteraction);

    if (widget.busy || !widget.rescueEnabled) {
      return KeyedSubtree(key: ValueKey(widget.note.id), child: interactive);
    }

    return Semantics(
      label: l10n.rescueNote,
      hint: widget.note.content,
      button: true,
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.rescueNote): widget.onRescue,
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
              child: FaIcon(TideIcons.surface, color: g.rescue, size: 20),
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
