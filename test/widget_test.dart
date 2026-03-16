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

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('submitButton')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('submit enables only when prompt and key are present', (
    WidgetTester tester,
  ) async {
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

    await tester.enterText(find.byKey(const Key('promptField')), '');
    await tester.pump();
    expect(button().onPressed, isNull);
  });
}

class FakeAiService implements AiService {
  FakeAiService({this.response = 'Stub response'});

  final String response;

  @override
  Future<String> generate({
    required String prompt,
    required String apiKey,
  }) async => response;
}
