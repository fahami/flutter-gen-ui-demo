import 'package:flutter/material.dart';

import 'ai_service.dart';
import 'app.dart';
import 'app_config.dart';

void main() {
  final config = AppConfig.fromEnvironment();

  runApp(GenkitDemoApp(config: config, aiService: GenkitAiService()));
}
