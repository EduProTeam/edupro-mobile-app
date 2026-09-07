# Course creator verification

New courses are not saved until their creator scores at least 7 out of 10 on an AI-generated subject quiz. For this academic-demo version, Flutter calls Gemini directly and keeps the answer key only in the running app's memory.

## One-time setup

1. Create a Gemini API key in Google AI Studio.
2. Run `flutter pub get` in the project root.
3. Start the app with `flutter run --dart-define=GEMINI_API_KEY=your_key_here`.

The app uses `gemini-2.0-flash`, generating only ten concise questions per attempt to preserve free-tier usage. Retrying generates a fresh quiz. This direct-client implementation is deliberately not production-secure: a determined user can inspect the compiled app and bypass client-side scoring.
