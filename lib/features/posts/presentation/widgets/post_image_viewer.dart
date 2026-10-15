import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showPostImageViewer(
  BuildContext context, {
  required String imageUrl,
  required String imageLabel,
}) => showDialog<void>(
  context: context,
  useSafeArea: false,
  builder: (dialogContext) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: 'Close image',
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: SizedBox.expand(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    semanticLabel: imageLabel,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (_, _, _) => const Center(
                      child: Text(
                        'Image unavailable',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
