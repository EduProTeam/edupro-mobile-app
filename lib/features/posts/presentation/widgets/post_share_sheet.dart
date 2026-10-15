import 'package:flutter/material.dart';

import '../../../../core/sharing/link_share_sheet.dart';
import '../../services/post_share_service.dart';

Future<void> showPostShareSheet(
  BuildContext context, {
  required String postId,
  required String postTitle,
  PostShareService? service,
}) {
  final sharing = service ?? PostShareService();
  return showLinkShareSheet(
    context,
    title: 'Share Post',
    onMessage: () => sharing.message(postId, postTitle),
    onWhatsApp: () => sharing.whatsapp(postId, postTitle),
    onCopyLink: () => sharing.copyLink(postId),
    copiedMessage: 'Post link copied.',
    failureMessage: 'Unable to share this post. Please try again.',
  );
}
