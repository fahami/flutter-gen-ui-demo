import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:genkit_demo/ai_service.dart';
import 'package:genkit_demo/app.dart';
import 'package:genkit_demo/app_config.dart';

void main() {
  testWidgets('shows runtime key guidance and disables submit by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GenkitDemoApp(config: const AppConfig(), aiService: FakeAiService()),
    );

    expect(
      find.textContaining('Stored in memory for this session only'),
      findsOneWidget,
    );
    expect(find.text('OpenRouter'), findsNothing);

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('submitButton')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('supports choosing the OpenRouter preset', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GenkitDemoApp(config: const AppConfig(), aiService: FakeAiService()),
    );

    await tester.ensureVisible(find.byKey(const Key('endpointPresetField')));
    await tester.tap(find.byKey(const Key('endpointPresetField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OpenRouter').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('OpenRouter gateway'), findsOneWidget);
    expect(find.text('OpenRouter'), findsWidgets);
  });

  testWidgets(
    'submit enables only when prompt, key, model, and endpoint are valid',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        GenkitDemoApp(config: const AppConfig(), aiService: FakeAiService()),
      );

      FilledButton button() =>
          tester.widget<FilledButton>(find.byKey(const Key('submitButton')));

      expect(button().onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('promptField')),
        'Explain what Genkit is.',
      );
      await tester.pump();
      expect(button().onPressed, isNull);

      await tester.enterText(find.byKey(const Key('apiKeyField')), 'test-key');
      await tester.pump();
      expect(button().onPressed, isNotNull);

      await tester.ensureVisible(find.byKey(const Key('endpointPresetField')));
      await tester.tap(find.byKey(const Key('endpointPresetField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom URL').last);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(TextField, 'https://your-provider.example.com/v1'),
        findsOneWidget,
      );
      expect(button().onPressed, isNotNull);

      await tester.enterText(find.byKey(const Key('customEndpointField')), '');
      await tester.pump();
      expect(button().onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('customEndpointField')),
        'https://api.example.com/v1',
      );
      await tester.pump();
      expect(button().onPressed, isNotNull);

      await tester.enterText(find.byKey(const Key('modelField')), '');
      await tester.pump();
      expect(button().onPressed, isNull);
    },
  );
}

class FakeAiService implements AiService {
  FakeAiService({this.response = 'Stub response'});

  final String response;

  @override
  Future<String> generate({
    required String prompt,
    required String apiKey,
    required String model,
    required String baseUrl,
  }) async => response;
}
