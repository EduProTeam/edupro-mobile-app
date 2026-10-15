import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a composer for review or copies a link; it never sends a message.
class LinkShareService {
  LinkShareService({
    required this.linkLabel,
    Future<bool> Function(Uri)? openUrl,
    Future<void> Function(String)? copyText,
  }) : _openUrl = openUrl ?? _launch,
       _copyText = copyText ?? _copy;

  final String linkLabel;
  final Future<bool> Function(Uri) _openUrl;
  final Future<void> Function(String) _copyText;

  static Future<bool> _launch(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  static Future<void> _copy(String text) =>
      Clipboard.setData(ClipboardData(text: text));

  Future<void> message(String text) async {
    final body = Uri.encodeComponent(text);
    // Use the common iOS composer-body convention; device support can vary.
    final uri = defaultTargetPlatform == TargetPlatform.iOS
        ? Uri.parse('sms:&body=$body')
        : Uri(scheme: 'sms', query: 'body=$body');
    if (!await _tryOpen(uri)) {
      throw LinkShareFailure(
        'Unable to open Messages. Try again or copy the $linkLabel.',
      );
    }
  }

  Future<void> whatsapp(String message) async {
    final text = Uri.encodeComponent(message);
    if (await _tryOpen(Uri.parse('whatsapp://send?text=$text'))) return;
    if (await _tryOpen(Uri.parse('https://wa.me/?text=$text'))) return;
    throw LinkShareFailure(
      'Unable to open WhatsApp. Try again or copy the $linkLabel.',
    );
  }

  Future<void> copyLink(Uri link) async {
    try {
      await _copyText(link.toString());
    } catch (_) {
      throw LinkShareFailure(
        'Unable to copy the $linkLabel. Please try again.',
      );
    }
  }

  Future<bool> _tryOpen(Uri uri) async {
    try {
      return await _openUrl(uri);
    } catch (_) {
      return false;
    }
  }
}

class LinkShareFailure implements Exception {
  const LinkShareFailure(this.message);
  final String message;
}
