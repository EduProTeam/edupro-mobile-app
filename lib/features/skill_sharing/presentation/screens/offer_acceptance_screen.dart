import 'package:flutter/material.dart';

import '../../models/skill_models.dart';
import '../../services/skill_sharing_store.dart';
import '../widgets/skill_ui.dart';
import 'schedule_session_screen.dart';

class OfferAcceptanceScreen extends StatefulWidget {
  const OfferAcceptanceScreen({super.key, this.store});

  final SkillSharingStore? store;

  @override
  State<OfferAcceptanceScreen> createState() => _OfferAcceptanceScreenState();
}

class _OfferAcceptanceScreenState extends State<OfferAcceptanceScreen> {
  late final SkillSharingStore _store =
      widget.store ?? SkillSharingStore.instance;
  String? _selectedId = 'ananya';

  @override
  Widget build(BuildContext context) {
    final request = _store.requests.first;
    return SkillPage(
      appBar: const SkillAppBar(
        title: 'Offer Acceptance',
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.more_vert),
          ),
        ],
      ),
      safeTop: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          SkillCard(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE1EEFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        color: SkillColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Request',
                            style: TextStyle(
                              color: SkillColors.secondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            request.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            request.description,
                            style: const TextStyle(
                              color: SkillColors.secondary,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SoftTag(
                      label: 'Online',
                      icon: Icons.computer_outlined,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: LabeledIconInfo(
                        icon: Icons.schedule,
                        label: 'Preferred Time',
                        value:
                            '${formatSkillDate(request.date)}  ${request.time}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LabeledIconInfo(
                        icon: Icons.signal_cellular_alt,
                        label: 'Level',
                        value: '',
                        trailing: LevelBadge(level: request.level),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Received Offers (${_store.offers.length})',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ..._store.offers.map(
            (offer) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OfferCard(
                offer: offer,
                selected: _selectedId == offer.id,
                onSelect: () => setState(() => _selectedId = offer.id),
                onAccept: () => _accept(offer),
              ),
            ),
          ),
          const InfoBanner(
            text:
                'Once you accept an offer, you’ll move to scheduling to confirm the session details.',
          ),
        ],
      ),
    );
  }

  void _accept(TutorOffer offer) {
    setState(() => _selectedId = offer.id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScheduleSessionScreen(store: _store, tutor: offer),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.selected,
    required this.onSelect,
    required this.onAccept,
  });

  final TutorOffer offer;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return SkillCard(
      borderColor: selected ? SkillColors.primary : SkillColors.border,
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PersonAvatar(
                initials: offer.initials,
                color: offer.avatarColor,
                radius: 27,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            offer.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (offer.recommended) ...[
                          const SizedBox(width: 6),
                          const SoftTag(label: '★ Recommended'),
                        ],
                      ],
                    ),
                    Text(
                      offer.title,
                      style: const TextStyle(
                        color: SkillColors.secondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '⭐ ${offer.rating} (${offer.reviews})    ${offer.sessions}+ Sessions',
                      style: const TextStyle(
                        color: SkillColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    offer.price == 0 ? '₹0' : '₹${offer.price}/session',
                    style: const TextStyle(
                      color: SkillColors.green,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Select ${offer.name}',
                    onPressed: onSelect,
                    icon: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected
                          ? SkillColors.primary
                          : SkillColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F7FD),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              offer.message,
              style: const TextStyle(
                color: SkillColors.secondary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: LabeledIconInfo(
                  icon: Icons.calendar_today_outlined,
                  label: 'Available',
                  value: offer.available,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: LabeledIconInfo(
                  icon: Icons.computer_outlined,
                  label: 'Mode',
                  value: 'Online',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 5,
              children: offer.tags.map((tag) => SoftTag(label: tag)).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: BlueButton(
                  label: 'View Profile',
                  icon: Icons.person_outline,
                  outlined: true,
                  compact: true,
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${offer.name} profile opened')),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BlueButton(
                  label: 'Accept Offer',
                  icon: Icons.send_outlined,
                  compact: true,
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
