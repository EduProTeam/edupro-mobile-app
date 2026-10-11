import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/skill_models.dart';
import '../../services/skill_sharing_store.dart';
import '../widgets/skill_ui.dart';
import 'offer_acceptance_screen.dart';
import 'publish_meeting_link_screen.dart';

enum _SessionTab { upcoming, requests, completed }

class MySessionsScreen extends StatefulWidget {
  const MySessionsScreen({super.key, this.store});

  final SkillSharingStore? store;

  @override
  State<MySessionsScreen> createState() => _MySessionsScreenState();
}

class _MySessionsScreenState extends State<MySessionsScreen> {
  late final SkillSharingStore _store =
      widget.store ?? SkillSharingStore.instance;
  _SessionTab _tab = _SessionTab.upcoming;
  bool _showBanner = true;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    _store.initializeRemote();
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _store.sessions
        .where((session) => session.status != SessionStatus.completed)
        .toList();
    final completed = _store.sessions
        .where((session) => session.status == SessionStatus.completed)
        .toList();
    final ownedSkillsWithRequests = _store.requests
        .where(
          (request) =>
              _store.isOwnRequest(request) &&
              _store.offersForRequest(request.id).isNotEmpty,
        )
        .toList();
    final sentRequests = _store.sentOffers;
    final pendingCount = _store.receivedOffers
            .where((offer) => offer.status == SkillRequestStatus.pending)
            .length +
        sentRequests
            .where((offer) => offer.status == SkillRequestStatus.pending)
            .length;
    final displayed = switch (_tab) {
      _SessionTab.upcoming => upcoming,
      _SessionTab.requests => const <SkillSession>[],
      _SessionTab.completed => completed,
    };
    return SkillPage(
      appBar: const SkillAppBar(
        title: 'My Sessions',
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.calendar_month_outlined,
              color: SkillColors.primary,
            ),
          ),
        ],
      ),
      safeTop: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          if (_showBanner) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCFE4FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.group_outlined,
                      color: SkillColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your skills. Their growth.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Track, join and manage your live skill-sharing sessions in one place.',
                          style: TextStyle(
                            color: SkillColors.secondary,
                            height: 1.35,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _showBanner = false),
                    icon: const Icon(Icons.close, color: SkillColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Expanded(
                child: _stat(
                  '${upcoming.length}',
                  'Upcoming\nSessions',
                  Icons.calendar_today_outlined,
                  SkillColors.primary,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _stat(
                  '$pendingCount',
                  'Pending\nRequests',
                  Icons.schedule,
                  SkillColors.orange,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _stat(
                  '${completed.length}',
                  'Completed\nSessions',
                  Icons.check_circle_outline,
                  SkillColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 45,
            decoration: BoxDecoration(
              border: Border.all(color: SkillColors.border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Expanded(child: _tabButton('Upcoming', _SessionTab.upcoming)),
                Expanded(child: _tabButton('Requests', _SessionTab.requests)),
                Expanded(child: _tabButton('Completed', _SessionTab.completed)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_tab == _SessionTab.requests &&
              (ownedSkillsWithRequests.isNotEmpty || sentRequests.isNotEmpty))
            ...[
              ...ownedSkillsWithRequests.map(
                (request) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PendingRequestCard(
                    request: request,
                    offerCount: _store.offersForRequest(request.id).length,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OfferAcceptanceScreen(
                          store: _store,
                          request: request,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ...sentRequests.map(
                (offer) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SentRequestCard(offer: offer),
                ),
              ),
            ]
          else if (displayed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: 46,
                    color: SkillColors.secondary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _tab == _SessionTab.requests
                        ? 'No pending requests'
                        : 'No sessions here yet',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: SkillColors.secondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...displayed.map(
              (session) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SessionCard(
                  session: session,
                  onPublish: () => _publish(session),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon, Color color) {
    return SkillCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: SkillColors.secondary,
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, _SessionTab tab) {
    final selected = _tab == tab;
    return InkWell(
      onTap: () => setState(() => _tab = tab),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? SkillColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : SkillColors.secondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _publish(SkillSession session) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PublishMeetingLinkScreen(store: _store, session: session),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({
    required this.request,
    required this.offerCount,
    required this.onOpen,
  });

  final SkillRequest request;
  final int offerCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SkillCard(
      child: Row(
        children: [
          PersonAvatar(
            initials: request.initials,
            color: request.avatarColor,
            imageUrl: request.profileImageUrl,
            radius: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$offerCount ${offerCount == 1 ? 'offer' : 'offers'} waiting for your response',
                  style: const TextStyle(
                    color: SkillColors.secondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Review offers',
            onPressed: onOpen,
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: SkillColors.primary,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _SentRequestCard extends StatelessWidget {
  const _SentRequestCard({required this.offer});

  final TutorOffer offer;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (offer.status) {
      SkillRequestStatus.pending => (
        'Pending',
        SkillColors.orange,
        Icons.schedule,
      ),
      SkillRequestStatus.accepted => (
        'Accepted',
        SkillColors.green,
        Icons.check_circle_outline,
      ),
      SkillRequestStatus.rejected => (
        'Rejected',
        Colors.red,
        Icons.cancel_outlined,
      ),
    };
    return SkillCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.requestTitle ?? 'Skill request',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Request sent to ${offer.recipientName ?? 'skill owner'}',
                      style: const TextStyle(
                        color: SkillColors.secondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              SoftTag(label: label, icon: icon),
            ],
          ),
          if (offer.status == SkillRequestStatus.accepted &&
              offer.scheduledDate != null &&
              offer.scheduledTime != null) ...[
            const Divider(height: 22),
            Text(
              '${formatSkillDate(offer.scheduledDate!)} • ${offer.scheduledTime}',
              style: const TextStyle(
                color: SkillColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (offer.status == SkillRequestStatus.rejected) ...[
            const SizedBox(height: 10),
            const InfoBanner(
              text:
                  'The skill owner declined this request. No meeting link is available.',
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onPublish});

  final SkillSession session;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (session.status) {
      SessionStatus.confirmed => ('Confirmed', SkillColors.green),
      SessionStatus.awaitingLink => ('Awaiting Link', SkillColors.orange),
      SessionStatus.completed => ('Completed', SkillColors.green),
    };
    return SkillCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PersonAvatar(
                initials: session.initials,
                color: session.avatarColor,
                radius: 28,
                online: session.status != SessionStatus.completed,
                imageUrl: session.profileImageUrl,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'with ${session.person}',
                      style: const TextStyle(
                        color: SkillColors.secondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.description,
                      style: const TextStyle(
                        color: SkillColors.secondary,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: .25)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: LabeledIconInfo(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date',
                  value: formatSkillDate(session.date),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: LabeledIconInfo(
                  icon: Icons.schedule,
                  label: 'Time',
                  value: session.time,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: LabeledIconInfo(
                  icon: Icons.computer_outlined,
                  label: 'Online',
                  value: session.meetingPlatform,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (session.status == SessionStatus.awaitingLink)
            Column(
              children: [
                InfoBanner(
                  text: session.canPublishLink
                      ? '${session.person} will receive the session link as soon as you publish it.'
                      : 'The skill owner has accepted your request. The meeting link has not been published yet.',
                ),
                if (session.canPublishLink) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: BlueButton(
                      label: 'Publish Meeting Link',
                      icon: Icons.add_link,
                      onPressed: onPublish,
                    ),
                  ),
                ],
              ],
            )
          else if (session.status == SessionStatus.confirmed)
            Column(
              children: [
                InfoBanner(
                  text:
                      '${session.meetingPlatform}: ${session.meetingLink ?? ''}',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: BlueButton(
                        label: 'Copy Link',
                        icon: Icons.copy_outlined,
                        outlined: true,
                        compact: true,
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: session.meetingLink ?? ''),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Meeting link copied.')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BlueButton(
                        label: 'Join Session',
                        icon: Icons.videocam_outlined,
                        compact: true,
                        onPressed: () => _joinSession(context, session),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: BlueButton(
                label: 'View Details & Notes',
                icon: Icons.description_outlined,
                outlined: true,
                onPressed: () {},
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _joinSession(
    BuildContext context,
    SkillSession session,
  ) async {
    final rawLink = session.meetingLink?.trim() ?? '';
    final normalizedLink = rawLink.startsWith('http://') ||
            rawLink.startsWith('https://')
        ? rawLink
        : 'https://$rawLink';
    final uri = Uri.tryParse(normalizedLink);

    if (rawLink.isEmpty ||
        uri == null ||
        !<String>{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The meeting link is not valid.')),
      );
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the meeting link.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the meeting link.')),
      );
    }
  }
}
