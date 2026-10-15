import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/blocked_word_filter.dart';

/// Loads the configurable policy once and validates all editable post text.
class PostModerationService {
  PostModerationService({Future<BlockedWordFilter> Function()? loadFilter})
    : _loadFilter = loadFilter ?? _loadAsset;

  static final shared = PostModerationService();
  static const assetPath = 'assets/moderation/blocked_words.json';
  static const unavailableMessage =
      'Unable to check your post. Please try again.';

  final Future<BlockedWordFilter> Function() _loadFilter;
  BlockedWordFilter? _cachedFilter;
  Future<BlockedWordFilter>? _loading;

  static Future<BlockedWordFilter> _loadAsset() async {
    final data = jsonDecode(await rootBundle.loadString(assetPath));
    if (data is! Map<String, dynamic>) {
      throw const FormatException('The blocked-word policy must be an object.');
    }
    return BlockedWordFilter.fromJson(data);
  }

  Future<BlockedWordFilter> _filter() async {
    final cached = _cachedFilter;
    if (cached != null) return cached;
    final loading = _loading ??= _loadFilter();
    try {
      final filter = await loading;
      _cachedFilter = filter;
      return filter;
    } finally {
      // Keep the resolved policy, not a Future bound to the caller's async zone.
      // Failed loads remain blocked, and a retry can reload the asset.
      if (identical(_loading, loading)) _loading = null;
    }
  }

  Future<Map<String, String>> validatePostText({
    required String title,
    required String content,
    required Iterable<String> tags,
  }) async {
    final BlockedWordFilter filter;
    try {
      filter = await _filter();
    } catch (_) {
      throw const PostModerationUnavailable();
    }

    return {
      for (final entry in {
        'title': title,
        'content': content,
        'tags': tags.join(' '),
      }.entries)
        if (filter.containsBlockedWord(entry.value))
          entry.key:
              'Remove inappropriate language from the ${entry.key} before saving your post.',
    };
  }
}

class PostModerationUnavailable implements Exception {
  const PostModerationUnavailable();
}
