import '../../../core/sharing/link_share_service.dart';
import '../models/profile_link.dart';

/// Opens a composer for the user to review; it never sends a message itself.
class ProfileShareService {
  ProfileShareService({
    Future<bool> Function(Uri)? openUrl,
    Future<void> Function(String)? copyText,
  }) : _sharing = LinkShareService(
         linkLabel: 'profile link',
         openUrl: openUrl,
         copyText: copyText,
       );

  final LinkShareService _sharing;

  Future<void> message(String userId, String profileName) =>
      _share(() => _sharing.message(_shareText(userId, profileName)));

  Future<void> whatsapp(String userId, String profileName) =>
      _share(() => _sharing.whatsapp(_shareText(userId, profileName)));

  Future<void> copyLink(String userId) =>
      _share(() => _sharing.copyLink(_link(userId)));

  Future<void> _share(Future<void> Function() action) async {
    try {
      await action();
    } on LinkShareFailure catch (error) {
      throw ProfileShareFailure(error.message);
    }
  }

  String _shareText(String userId, String profileName) {
    final name = profileName.trim().isEmpty
        ? 'this profile'
        : profileName.trim();
    return 'View $name on EduPro:\n${_link(userId)}';
  }

  Uri _link(String userId) {
    try {
      return ProfileLink.forUser(userId);
    } catch (_) {
      throw const ProfileShareFailure(
        'Unable to create this profile link. Please try again.',
      );
    }
  }
}

class ProfileShareFailure extends LinkShareFailure {
  const ProfileShareFailure(super.message);
}
