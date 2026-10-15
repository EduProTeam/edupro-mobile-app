import 'package:flutter/material.dart';

import 'link_share_service.dart';

Future<void> showLinkShareSheet(
  BuildContext context, {
  required String title,
  required Future<void> Function() onMessage,
  required Future<void> Function() onWhatsApp,
  required Future<void> Function() onCopyLink,
  required String copiedMessage,
  required String failureMessage,
}) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _LinkShareSheet(
      title: title,
      onMessage: onMessage,
      onWhatsApp: onWhatsApp,
      onCopyLink: onCopyLink,
      copiedMessage: copiedMessage,
      failureMessage: failureMessage,
      messenger: messenger,
    ),
  );
}

class _LinkShareSheet extends StatefulWidget {
  const _LinkShareSheet({
    required this.title,
    required this.onMessage,
    required this.onWhatsApp,
    required this.onCopyLink,
    required this.copiedMessage,
    required this.failureMessage,
    required this.messenger,
  });

  final String title;
  final Future<void> Function() onMessage;
  final Future<void> Function() onWhatsApp;
  final Future<void> Function() onCopyLink;
  final String copiedMessage;
  final String failureMessage;
  final ScaffoldMessengerState messenger;

  @override
  State<_LinkShareSheet> createState() => _LinkShareSheetState();
}

class _LinkShareSheetState extends State<_LinkShareSheet> {
  String? _active;
  String? _error;

  Future<void> _share(
    String label,
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    if (_active != null) return;
    setState(() {
      _active = label;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      if (successMessage != null) _showMessage(successMessage);
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      final message = error is LinkShareFailure
          ? error.message
          : widget.failureMessage;
      setState(() => _error = message);
      _showMessage(message);
    } finally {
      if (mounted) setState(() => _active = null);
    }
  }

  void _showMessage(String message) {
    if (!widget.messenger.mounted) return;
    widget.messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _option(String label, IconData icon, VoidCallback onTap) => ListTile(
    enabled: _active == null,
    leading: Icon(icon),
    title: Text(label),
    trailing: _active == label
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : null,
    onTap: _active == null ? onTap : null,
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close sharing options',
                    onPressed: _active == null
                        ? () => Navigator.of(context).pop()
                        : null,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            _option(
              'Message',
              Icons.sms_outlined,
              () => _share('Message', widget.onMessage),
            ),
            _option(
              'WhatsApp',
              Icons.chat_outlined,
              () => _share('WhatsApp', widget.onWhatsApp),
            ),
            _option(
              'Copy Link',
              Icons.link,
              () => _share(
                'Copy Link',
                widget.onCopyLink,
                successMessage: widget.copiedMessage,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
