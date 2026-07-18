import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('composer'),
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('composer-input'),
                  controller: _controller,
                  focusNode: _focusNode,
                  minLines: 2,
                  maxLines: 6,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: 'Capture a thought…',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(18, 14, 8, 14),
                  ),
                ),
              ),
              Semantics(
                label: 'Save note',
                button: true,
                child: IconButton(
                  onPressed: _submit,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    ),
  );
}
