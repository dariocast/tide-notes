import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tide/design/design_helpers.dart';
import 'package:tide/design/theme.dart';
import 'package:tide/l10n/tide_localizations.dart';
import 'package:tide/presentation/widgets/tide_search_header.dart';

void main() {
  testWidgets('clear action clears text and keeps search focused', (
    tester,
  ) async {
    await tester.pumpWidget(const _SearchHarness(initialText: 'todo'));
    await tester.tap(find.byKey(const ValueKey('search-input')));
    await tester.pump();

    final clearAction = find.byKey(const ValueKey('clear-search'));
    expect(clearAction, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('clear-search')));
    await tester.pump();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('search-input')),
    );
    expect(field.controller!.text, isEmpty);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(clearAction, findsNothing);
  });

  testWidgets('Italian search header exposes localized controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _SearchHarness(locale: Locale('it'), initialText: 'nota'),
    );

    expect(find.text('Cerca nelle note…'), findsOneWidget);
    expect(find.byTooltip('Cancella testo di ricerca'), findsOneWidget);
    expect(find.text('Cancella'), findsOneWidget);
  });

  testWidgets('vertically centers search text with its leading icon', (
    tester,
  ) async {
    await tester.pumpWidget(const _SearchHarness());

    final header = find.byKey(const ValueKey('search-header'));
    final icon = find.descendant(
      of: header,
      matching: find.byWidgetPredicate((widget) => widget is FaIcon),
    );
    final field = find.descendant(
      of: header,
      matching: find.byType(EditableText),
    );

    expect(
      (tester.getCenter(icon).dy - tester.getCenter(field).dy).abs(),
      lessThanOrEqualTo(1),
    );
  });
}

class _SearchHarness extends StatefulWidget {
  const _SearchHarness({
    this.locale = const Locale('en'),
    this.initialText = '',
  });

  final Locale locale;
  final String initialText;

  @override
  State<_SearchHarness> createState() => _SearchHarnessState();
}

class _SearchHarnessState extends State<_SearchHarness> {
  late final TextEditingController controller;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: widget.locale,
    supportedLocales: const [Locale('en'), Locale('it')],
    localizationsDelegates: const [
      TideLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    theme: TideAppTheme.foam,
    home: Scaffold(
      body: GSizeClassScope(
        sizeClass: GSizeClass.compact,
        child: TideSearchHeader(
          controller: controller,
          focusNode: focusNode,
          onChanged: (_) => setState(() {}),
          onClear: () {
            controller.clear();
            setState(() {});
            focusNode.requestFocus();
          },
          onClose: () {},
        ),
      ),
    ),
  );
}
