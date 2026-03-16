# genkit_demo

Minimal Flutter demo that sends a single prompt through `genkit` using the
`genkit_openai` plugin.

## Run

```bash
flutter run \
  --dart-define=OPENAI_MODEL=gpt-4o-mini \
  --dart-define=OPENAI_BASE_URL=https://api.openai.com/v1
```

`OPENAI_MODEL` and `OPENAI_BASE_URL` are optional. If omitted, the app defaults
to `gpt-4o-mini` and `https://api.openai.com/v1`. The API key is entered inside
the app at runtime, and users can switch endpoint presets in the UI.

## Web

Run in a browser locally:

```bash
flutter run -d chrome \
  --dart-define=OPENAI_MODEL=gpt-4o-mini \
  --dart-define=OPENAI_BASE_URL=https://api.openai.com/v1
```

Build static web assets:

```bash
flutter build web \
  --dart-define=OPENAI_MODEL=gpt-4o-mini \
  --dart-define=OPENAI_BASE_URL=https://api.openai.com/v1
```

## Notes

- The app is now BYOK: each user enters an API key in the UI for the current
  session, and the app does not write that key to disk.
- Supported in-app endpoint presets include `OpenAI`, `OpenRouter`, `Groq`,
  and a `Custom URL` option for any other OpenAI-compatible base URL.
- On `web`, requests still go directly from the browser to the configured model
  endpoint, so users should only enter keys they control and trust this client.
- If you want a turnkey public app for non-technical users, move the model call
  behind a backend or Genkit remote flow instead of requiring end-user keys.
