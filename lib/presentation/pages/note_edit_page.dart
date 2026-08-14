import 'package:flutter/material.dart';

import '../../design/design_helpers.dart';
import '../../design/design_tokens.dart';
import '../../design/tide_icons.dart';
import '../../design/tide_markdown.dart';
import '../../l10n/tide_localizations.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Full-screen editing surface opened via long-press on a [NoteCard].
///
/// This is additive to Tide's existing inline edit-in-place: tapping a note
/// still begins the inline edit unchanged, while long-pressing opens this
/// page with a plain-text field and a live markdown preview underneath.
class NoteEditPage extends StatefulWidget {
  const NoteEditPage({super.key, required this.content, required this.onSave});

  final String content;
  final ValueChanged<String> onSave;

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = TideLocalizations.of(context);
    final g = tideColorsOf(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GSpace.s4,
                vertical: GSpace.s2,
              ),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('edit-page-close'),
                    tooltip: l10n.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const FaIcon(TideIcons.clearSearch, size: 20),
                  ),
                  const Spacer(),
                  IconButton(
                    key: const ValueKey('edit-page-confirm'),
                    tooltip: l10n.saveNote,
                    onPressed: () {
                      widget.onSave(_controller.text);
                      Navigator.of(context).pop();
                    },
                    icon: const FaIcon(TideIcons.check, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: GSpace.s4),
                child: TextField(
                  key: const ValueKey('edit-page-input'),
                  controller: _controller,
                  maxLines: null,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(GSpace.s4),
                child: _markdownBody == null
                    ? Text(
                        l10n.editPreviewEmpty,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: g.textMuted),
                      )
                    : MarkdownBody(
                        data: _markdownBody!,
                        styleSheet: tideMarkdownStyleSheet(context),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Only lines after the first are live-previewed as markdown, mirroring
  // NoteCard's own split (from Task 5): its first line is a plain
  // prefix/title that never goes through MarkdownBody, and only the body
  // after it is markdown-rendered. See `markdownBodyFor` for the shared
  // rule both call sites use.
  //
  // Beyond consistency, this also sidesteps a real widget-matching problem:
  // feeding the *whole* text (title line included) to a single MarkdownBody
  // call merges adjacent non-blank lines into one CommonMark paragraph
  // joined by a soft line break -- "idea: title\n**bold**" would render as
  // one Text.rich whose plain text is "idea: title bold", with no separate
  // widget whose text is just "bold". And previewing the title line
  // wouldn't help either: for a plain (non-markdown) single-line note the
  // preview's rendered text would be byte-identical to the input field's
  // text, so `find.text(...)` would match both the input and the preview
  // and no longer resolve to a single widget.
  String? get _markdownBody => markdownBodyFor(_controller.text);
}
