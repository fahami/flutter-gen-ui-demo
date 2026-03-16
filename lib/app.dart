import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ai_service.dart';
import 'app_config.dart';

class GenkitDemoApp extends StatelessWidget {
  const GenkitDemoApp({
    super.key,
    required this.config,
    required this.aiService,
  });

  final AppConfig config;
  final AiService aiService;

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0B6E4F),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F1E8),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );

    return MaterialApp(
      title: 'Genkit OpenAI Demo',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: DemoHomePage(config: config, aiService: aiService),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({
    super.key,
    required this.config,
    required this.aiService,
  });

  final AppConfig config;
  final AiService aiService;

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _customEndpointController =
      TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  late EndpointPreset _selectedEndpoint;

  bool _isLoading = false;
  bool _obscureApiKey = true;
  String? _errorMessage;
  String? _responseText;

  bool get _hasPrompt => _promptController.text.trim().isNotEmpty;
  bool get _hasApiKey => _apiKeyController.text.trim().isNotEmpty;
  bool get _hasModel => _modelController.text.trim().isNotEmpty;
  String get _resolvedBaseUrl => _selectedEndpoint.isCustom
      ? _customEndpointController.text.trim()
      : _selectedEndpoint.baseUrl;
  bool get _hasValidEndpointUrl {
    final uri = Uri.tryParse(_resolvedBaseUrl);
    return uri != null &&
        uri.hasScheme &&
        (uri.host.isNotEmpty || uri.authority.isNotEmpty);
  }

  bool get _canSubmit =>
      !_isLoading &&
      _hasApiKey &&
      _hasPrompt &&
      _hasModel &&
      _hasValidEndpointUrl;

  @override
  void initState() {
    super.initState();
    _selectedEndpoint = EndpointPreset.fromBaseUrl(widget.config.baseUrl);
    _modelController.text = widget.config.model;
    if (_selectedEndpoint.isCustom) {
      _customEndpointController.text = widget.config.baseUrl;
    }

    _apiKeyController.addListener(_handleInputChanged);
    _modelController.addListener(_handleInputChanged);
    _customEndpointController.addListener(_handleInputChanged);
    _promptController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _apiKeyController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _modelController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _customEndpointController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _promptController
      ..removeListener(_handleInputChanged)
      ..dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    setState(() {});
  }

  void _updateEndpoint(EndpointPreset? preset) {
    if (preset == null) {
      return;
    }

    setState(() {
      _selectedEndpoint = preset;
      if (!preset.isCustom) {
        _customEndpointController.clear();
      } else if (_customEndpointController.text.trim().isEmpty) {
        _customEndpointController.text = widget.config.baseUrl;
      }
    });
  }

  Future<void> _submitPrompt() async {
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _responseText = null;
    });

    try {
      final response = await widget.aiService.generate(
        prompt: _promptController.text,
        apiKey: _apiKeyController.text,
        model: _modelController.text,
        baseUrl: _resolvedBaseUrl,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _responseText = response;
      });
    } on AiServiceException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unexpected error: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F6EE), Color(0xFFF5F1E8)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Genkit + OpenAI-compatible demo',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bring your own key, switch between OpenAI-compatible endpoints, and adjust the model at runtime without rebuilding the app.',
                    style: textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        label: 'Endpoint',
                        value: _selectedEndpoint.label,
                      ),
                      _InfoChip(
                        label: 'Model',
                        value: _modelController.text.trim(),
                      ),
                      _InfoChip(label: 'Base URL', value: _resolvedBaseUrl),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (kIsWeb) ...[
                    const _StatusPanel(
                      title: 'Browser request path',
                      message:
                          'This web build sends requests directly from the browser to the selected endpoint. Your key is entered at runtime, but users should still only use keys they control and trust this client.',
                      tone: _PanelTone.warning,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Card(
                    elevation: 0,
                    color: Colors.white.withValues(alpha: 0.92),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connection',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<EndpointPreset>(
                            key: const Key('endpointPresetField'),
                            initialValue: _selectedEndpoint,
                            decoration: const InputDecoration(
                              labelText: 'Endpoint preset',
                            ),
                            items: [
                              for (final preset in EndpointPreset.values)
                                DropdownMenuItem<EndpointPreset>(
                                  value: preset,
                                  child: Text(preset.label),
                                ),
                            ],
                            onChanged: _updateEndpoint,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedEndpoint.helperText,
                            style: textTheme.bodySmall,
                          ),
                          if (_selectedEndpoint.isCustom) ...[
                            const SizedBox(height: 16),
                            TextField(
                              key: const Key('customEndpointField'),
                              controller: _customEndpointController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'Custom endpoint URL',
                                hintText:
                                    'https://your-provider.example.com/v1',
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            key: const Key('modelField'),
                            controller: _modelController,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              labelText: 'Model',
                              hintText: 'gpt-4o-mini',
                              helperText:
                                  'Choose a model name that exists on the selected provider.',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            key: const Key('apiKeyField'),
                            controller: _apiKeyController,
                            obscureText: _obscureApiKey,
                            enableSuggestions: false,
                            autocorrect: false,
                            keyboardType: TextInputType.visiblePassword,
                            decoration: InputDecoration(
                              labelText: 'API key',
                              hintText: 'Paste an OpenAI-compatible API key',
                              helperText:
                                  'Stored in memory for this session only. Not written to disk by the app.',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureApiKey = !_obscureApiKey;
                                  });
                                },
                                icon: Icon(
                                  _obscureApiKey
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Prompt',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('promptField'),
                            controller: _promptController,
                            minLines: 5,
                            maxLines: 8,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              hintText:
                                  'Example: Summarize what Genkit gives a Flutter prototype and suggest one next improvement.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _canSubmit
                                ? 'Ready to send the prompt.'
                                : 'Fill in an API key, model, prompt, and a valid endpoint URL.',
                            style: textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              key: const Key('submitButton'),
                              onPressed: _canSubmit ? _submitPrompt : null,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome),
                              label: Text(
                                _isLoading ? 'Generating...' : 'Generate',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _StatusPanel(
                      key: const Key('errorPanel'),
                      title: 'Request failed',
                      message: _errorMessage!,
                      tone: _PanelTone.error,
                    ),
                  ],
                  if (_responseText != null) ...[
                    const SizedBox(height: 16),
                    _StatusPanel(
                      key: const Key('responsePanel'),
                      title: 'Response',
                      message: _responseText!,
                      tone: _PanelTone.success,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: value.isEmpty ? 'Not set' : value),
            ],
          ),
        ),
      ),
    );
  }
}

enum _PanelTone { warning, error, success }

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    super.key,
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final _PanelTone tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (backgroundColor, borderColor, icon) = switch (tone) {
      _PanelTone.warning => (
        const Color(0xFFFFF3D6),
        const Color(0xFFE4B64F),
        Icons.key_off,
      ),
      _PanelTone.error => (
        const Color(0xFFFBE4E6),
        const Color(0xFFD7646A),
        Icons.error_outline,
      ),
      _PanelTone.success => (
        const Color(0xFFDFF3EA),
        const Color(0xFF3B8F69),
        Icons.chat_bubble_outline,
      ),
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
