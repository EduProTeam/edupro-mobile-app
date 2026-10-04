# Course creator verification

New courses are not saved until their creator scores at least 4 out of 5 on a predefined, topic-specific quiz. No external AI service or API key is used.

## One-time setup

1. Run `flutter pub get` in the project root.
2. Start the app with `flutter run`.

The course title chooses the quiz topic within its selected category. Development supports Python, Java, JavaScript, C#, SQL, Flutter, Dart, HTML, CSS, and React. Design & UI/UX, Marketing, and Business each have ten supported subtopics; Other has five general-skills topics. Each topic has five predefined questions. Retrying restarts the same topic quiz. This client-side implementation is suitable for an academic demonstration, not production security.
