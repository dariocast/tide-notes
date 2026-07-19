import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';

class SubmitIntent extends Intent {
  const SubmitIntent();
}

class NoteComposer extends StatefulWidget {
  const NoteComposer({
    super.key,
    required this.onSubmit,
    required this.appendCompleted,
  });

  final ValueChanged<String> onSubmit;
  final int appendCompleted;

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
  }

  @override
  void didUpdateWidget(covariant NoteComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appendCompleted <= _lastAppendCompleted) return;
    _lastAppendCompleted = widget.appendCompleted;
    if (_pendingContent != null && _controller.text == _pendingContent) {
      _controller.clear();
      _pendingContent = null;
      _focusNode.requestFocus();
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
    return Padding(
      key: const ValueKey('composer'),
      padding: EdgeInsets.fromLTRB(
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s2,
        compact ? GSpace.s4 : GSpace.s6,
        GSpace.s3,
      ),
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter, meta: true): SubmitIntent(),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('composer-input'),
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 2,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'Capture a thought…',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: GSpace.s4,
                        vertical: GSpace.s3,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  label: 'Save note',
                  button: true,
                  onTap: _submit,
                  child: ExcludeSemantics(
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Icon(Icons.arrow_upward_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: GSpace.s2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
