# Configurable blocked words for posts

Edit `assets/moderation/blocked_words.json` to manage the list:

```json
{
  "blockedWords": ["exampleword", "example phrase"]
}
```

The checked-in list contains common English profanity. Add the Sinhala, Tamil,
romanized spellings, and other language entries your community needs. Entries
are literal words or phrases containing Unicode letters, combining marks,
numbers, and spaces; do not enter regular expressions. Invalid entries stop
configuration loading or rule generation. Case and duplicate entries are
normalized. An empty `blockedWords` list explicitly disables word filtering.

The app checks title, content, and tags when publishing, saving a draft, or
editing a post. Validation happens before media uploads and Firestore writes.
The form keeps the user's text and shows the affected fields so they can correct
the post. Matching uses word boundaries to avoid blocking innocent substrings,
accepts punctuation or spaces inserted between letters, and recognizes common
substitutions such as `a/@/4`, `e/3`, `i/1/!`, `o/0`, `s/$/5`, and `t/7`.

## Keep the app and Firestore rules in sync

The same pure Dart filter generates the rule pattern. After changing the list,
run these commands from the repository root:

```powershell
dart run tool/sync_post_moderation.dart
dart run tool/sync_post_moderation.dart --check
flutter test test/post_moderation_rules_test.dart
```

The script updates only the marked body of `postHasAllowedText` in
`firestore.rules`. `--check` exits unsuccessfully when the configuration and
checked-in pattern differ. It performs no deployment. Commit the configuration
and generated rules together, rebuild/release the app so it bundles the new
list, and deploy the updated rules through your normal Firebase release process
(`firebase deploy --only firestore:rules`). Changing this file is a build-time
configuration update; the running app does not fetch list changes remotely.

Firestore rejects blocked title/content/tag text on creation, on edits to those
fields, and on status changes such as publishing a legacy draft. A standard
owner soft-delete patch can still remove legacy flagged content; counter-only
updates remain available. Text mixed into counter or delete patches must pass
moderation. Updates cannot transfer the post's author `userId`.

Rules validate the title and content as strings and tags as a list. They
lowercase the fields and check every tag through `tags.join(' ')`.
[Firebase `List.join`](https://firebase.google.com/docs/reference/rules/rules.List#join)
supports combining tags into a single string. [Firebase `String.matches`](https://firebase.google.com/docs/reference/rules/rules.String#matches)
matches the whole string using RE2, so the generated pattern includes a dot-all
prefix and surrounding wildcards to find blocked words in multiline content.

## Verify enforcement with the local emulator

The pure Dart tests check generated-rule drift, regex parity, whole-word
boundaries, multiline content, Unicode entries, and the disabled-list behavior.
The standalone emulator script additionally checks real RE2 evaluation and
Firestore create/update permissions, including attempts to bypass moderation
through counters, publishing drafts, ownership changes, and legacy soft deletes.
It requires Node.js, the Firebase CLI, and Java 21 or newer; the CLI may download
its emulator on first use. No npm test dependencies are required.

```powershell
firebase emulators:exec --config firebase.moderation-test.json --only firestore --project demo-edupro-post-moderation "node tool/test_post_moderation_rules.mjs"
```

The test script requires a local emulator host and a `demo-` project ID. It writes
only temporary emulator documents and cannot target the production project.

A blocked-word list does not understand context and does not catch every
obfuscation, misspelling, Unicode lookalike, or unlisted grammatical variation.
Review the list for unintended matches and include relevant variants. This
feature checks typed post text; comments, image/video content, attachment files,
and linked pages require separate moderation. Existing published posts are not
automatically scanned or removed when the list changes.
