import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_gemma_chat/core/widgets/glass_container.dart';
import 'package:flutter_gemma_chat/core/widgets/gradient_background.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('GlassContainer', () {
    testWidgets('renders its child', (tester) async {
      await tester.pumpWidget(
        _wrap(const GlassContainer(child: Text('hello glass'))),
      );

      expect(find.text('hello glass'), findsOneWidget);
    });

    testWidgets('applies padding when provided', (tester) async {
      const key = ValueKey('inner');
      await tester.pumpWidget(
        _wrap(
          const GlassContainer(
            padding: EdgeInsets.all(24),
            child: SizedBox(key: key, width: 10, height: 10),
          ),
        ),
      );

      final inner = tester.getRect(find.byKey(key));
      expect(inner.width, 10);
      expect(inner.height, 10);
    });
  });

  group('GlassCard', () {
    testWidgets('invokes onTap when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          GlassCard(
            onTap: () => taps++,
            child: const Text('tap me'),
          ),
        ),
      );

      await tester.tap(find.text('tap me'));
      await tester.pump();

      expect(taps, 1);
    });
  });

  group('GradientBackground', () {
    testWidgets('renders its child over the gradient', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GradientBackground(
            child: Scaffold(body: Center(child: Text('content'))),
          ),
        ),
      );

      expect(find.text('content'), findsOneWidget);
    });
  });
}
