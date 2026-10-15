import 'package:flutter/material.dart';

import '../../../../core/sharing/link_share_sheet.dart';
import '../../services/profile_share_service.dart';

Future<void> showProfileShareSheet(
  BuildContext context, {
  required String userId,
  required String profileName,
  ProfileShareService? service,
}) {
  final sharing = service ?? ProfileShareService();
  return showLinkShareSheet(
    context,
    title: 'Share Profile',
    onMessage: () => sharing.message(userId, profileName),
    onWhatsApp: () => sharing.whatsapp(userId, profileName),
    onCopyLink: () => sharing.copyLink(userId),
    copiedMessage: 'Profile link copied.',
    failureMessage: 'Unable to share this profile. Please try again.',
  );
}
