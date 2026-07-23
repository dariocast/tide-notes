import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../design/tide_icons.dart';
import '../../l10n/tide_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SubmitIntent extends Intent {
  const SubmitIntent();
}

class NoteComposer extends StatefulWidget {
  const NoteComposer({
    super.key,
    required this.onSubmit,
    required this.appendCompleted,
    this.submitOnEnter = false,
  });

  final ValueChanged<String> onSubmit;
  final int appendCompleted;
  final bool submitOnEnter;

  @override
  State<NoteComposer> createState() => _NoteComposerState();
}

class _NoteComposerState extends State<NoteComposer> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late int _lastAppendCompleted;
  String? _pendingContent;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _lastAppendCompleted = widget.appendCompleted;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant NoteComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appendCompleted <= _lastAppendCompleted) return;
    _lastAppendCompleted = widget.appendCompleted;
    if (_pendingContent != null && _controller.text == _pendingContent) {
      _controller.clear();
      _pendingContent = null;
      if (widget.submitOnEnter) _focusNode.requestFocus();
    }
  }

  void _submit() {
    final content = _controller.text;
    if (content.trim().isEmpty) return;
    _pendingContent = content;
    widget.onSubmit(content);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = sizeClassOf(context) == GSizeClass.compact;
    final g = tideColorsOf(context);
    final l10n = TideLocalizations.of(context);
    return Padding(
      key: const ValueKey('composer'),
      padding: EdgeInsets.fromLTRB(
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s2,
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s2,
      ),
      child: Shortcuts(
        shortcuts: {
          if (widget.submitOnEnter)
            const SingleActivator(LogicalKeyboardKey.enter): SubmitIntent(),
          const SingleActivator(LogicalKeyboardKey.enter, meta: true):
              SubmitIntent(),
        },
        child: Actions(
          actions: {
            SubmitIntent: CallbackAction<SubmitIntent>(
              onInvoke: (_) {
                _submit();
                return null;
              },
            ),
          },
          child: FocusRing(
            borderRadius: GShapes.composer,
            child: DecoratedBox(
              key: const ValueKey('composer-surface'),
              decoration: BoxDecoration(
                color: g.surfaceElevated,
                border: Border.all(color: g.lineSubtle),
                borderRadius: GShapes.composer,
              ),
              child: ClipRRect(
                borderRadius: GShapes.composer,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('composer-input'),
                        controller: _controller,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        keyboardType: TextInputType.multiline,
                        textInputAction: widget.submitOnEnter
                            ? TextInputAction.done
                            : TextInputAction.newline,
                        onSubmitted: widget.submitOnEnter
                            ? (_) => _submit()
                            : null,
                        onTapOutside: (_) => _focusNode.unfocus(),
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: l10n.captureHint,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: GSpace.s4,
                            vertical: GSpace.s2,
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      label: l10n.saveNote,
                      button: true,
                      onTap: _submit,
                      child: IconButton(
                        onPressed: _submit,
                        tooltip: l10n.saveNote,
                        icon: const FaIcon(TideIcons.insert, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
