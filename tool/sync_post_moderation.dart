import 'dart:convert';
import 'dart:io';

import 'package:edupro_mobile_app/features/posts/models/blocked_word_filter.dart';

const postModerationStartMarker =
    '      // BEGIN GENERATED POST MODERATION — do not edit by hand';
const postModerationEndMarker = '      // END GENERATED POST MODERATION';

/// Generates only the body of `postHasAllowedText` in firestore.rules.
/// JSON string encoding preserves literal quotes and regex backslashes.
String generatePostModerationRulesBody(BlockedWordFilter filter) {
  const shape = '''      return data.title is string
             && data.content is string
             && data.tags is list''';
  if (!filter.enabled) {
    return '''      // The configured blocked-word list is empty; text filtering is disabled.
$shape;
''';
  }
  final pattern = jsonEncode(filter.firestorePattern);
  return '''      let blockedPattern = $pattern;
$shape
             && !data.title.lower().matches(blockedPattern)
             && !data.content.lower().matches(blockedPattern)
             && !data.tags.join(' ').lower().matches(blockedPattern);
''';
}

/// Replaces the marked body and leaves the rest of the rules byte-for-byte.
String synchronizePostModerationRules(String rules, BlockedWordFilter filter) {
  final lineEnding = rules.contains('\r\n') ? '\r\n' : '\n';
  final start = rules.indexOf(postModerationStartMarker);
  final end = rules.indexOf(postModerationEndMarker);
  if (start < 0 ||
      end <= start ||
      rules.indexOf(postModerationStartMarker, start + 1) >= 0 ||
      rules.indexOf(postModerationEndMarker, end + 1) >= 0) {
    throw const FormatException(
      'firestore.rules must contain exactly one ordered moderation marker pair.',
    );
  }
  final bodyStart = start + postModerationStartMarker.length;
  return rules.substring(0, bodyStart) +
      lineEnding +
      generatePostModerationRulesBody(filter).replaceAll('\n', lineEnding) +
      rules.substring(end);
}

Future<void> main(List<String> arguments) async {
  if (arguments.any((argument) => argument != '--check') ||
      arguments.length > 1) {
    stderr.writeln('Usage: dart run tool/sync_post_moderation.dart [--check]');
    exitCode = 64;
    return;
  }
  try {
    // Resolve from this script so invocation also works from another directory.
    final root = File.fromUri(Platform.script).parent.parent;
    final configFile = File.fromUri(
      root.uri.resolve('assets/moderation/blocked_words.json'),
    );
    final config = jsonDecode(await configFile.readAsString());
    if (config is! Map<String, dynamic>) {
      throw const FormatException(
        'Blocked-word configuration must be an object.',
      );
    }
    final filter = BlockedWordFilter.fromJson(config);
    final rulesFile = File.fromUri(root.uri.resolve('firestore.rules'));
    final existing = await rulesFile.readAsString();
    final synchronized = synchronizePostModerationRules(existing, filter);
    if (arguments.contains('--check')) {
      if (existing != synchronized) {
        stderr.writeln(
          'Post moderation rules are out of date. '
          'Run dart run tool/sync_post_moderation.dart.',
        );
        exitCode = 1;
        return;
      }
      stdout.writeln('Post moderation rules match the blocked-word list.');
      return;
    }
    if (existing != synchronized) {
      await rulesFile.writeAsString(synchronized);
    }
    stdout.writeln(
      'Post moderation rules synchronized. No rules were deployed.',
    );
  } on FormatException catch (error) {
    stderr.writeln('Invalid post moderation configuration: ${error.message}');
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln('Unable to synchronize post moderation: ${error.message}');
    exitCode = 1;
  }
}
