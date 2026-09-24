import 'package:flutter/material.dart';

import '../../models/skill_models.dart';
import '../../services/skill_sharing_store.dart';
import '../widgets/skill_ui.dart';
import 'my_sessions_screen.dart';

class ScheduleSessionScreen extends StatefulWidget {
  const ScheduleSessionScreen({super.key, required this.tutor, this.store});

  final TutorOffer tutor;
  final SkillSharingStore? store;

  @override
  State<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  late final SkillSharingStore _store =
      widget.store ?? SkillSharingStore.instance;
  final _noteController = TextEditingController();
  int _selectedDate = 3;
  String _selectedTime = '4:00 PM';
  int _duration = 60;
  String _platform = 'Google Meet';

  static final _dates = List<DateTime>.generate(
    7,
    (index) => DateTime(2025, 5, 18 + index),
  );
  static const _times = <String>[
    '3:00 PM',
    '3:30 PM',
    '4:00 PM',
    '4:30 PM',
    '5:00 PM',
    '5:30 PM',
    '6:00 PM',
    '6:30 PM',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SkillPage(
      appBar: const SkillAppBar(title: 'Schedule Session'),
      safeTop: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        children: [
          _summary(),
          const SizedBox(height: 14),
          SkillCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Date',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dates.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 7),
                    itemBuilder: (context, index) {
                      final date = _dates[index];
                      final selected = index == _selectedDate;
                      const weekdays = <String>[
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ];
                      return InkWell(
                        onTap: () => setState(() => _selectedDate = index),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 58,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? SkillColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                weekdays[date.weekday - 1],
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : SkillColors.navy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'May',
                                style: TextStyle(
                                  color: selected
                                      ? const Color(0xFFD7E9FF)
                                      : SkillColors.secondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : SkillColors.navy,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 21,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                const InfoBanner(
                  text: 'All times shown in India Standard Time (IST)',
                ),
                const Divider(height: 28),
                const Text(
                  'Available Time Slots',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _times.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) => _choice(
                    _times[index],
                    _selectedTime == _times[index],
                    () => setState(() => _selectedTime = _times[index]),
                    compact: true,
                  ),
                ),
                const Divider(height: 30),
                const Text(
                  'Session Duration',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _choice(
                        '30 min\nQuick session',
                        _duration == 30,
                        () => setState(() => _duration = 30),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _choice(
                        '60 min\nRecommended',
                        _duration == 60,
                        () => setState(() => _duration = 60),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _choice(
                        '90 min\nIn-depth session',
                        _duration == 90,
                        () => setState(() => _duration = 90),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                const Text(
                  'Platform Preference',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _platformChoice(
                        'Google Meet',
                        Icons.video_camera_front_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _platformChoice('Zoom', Icons.videocam_outlined),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _platformChoice(
                        'Microsoft Teams',
                        Icons.groups_outlined,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                const Text(
                  'Add a note (optional)',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 9),
                TextField(
                  controller: _noteController,
                  maxLength: 250,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Any specific topics, materials, or instructions?',
                    hintStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const InfoBanner(
                  text:
                      'You will receive a calendar invite and session link after confirming.',
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: BlueButton(
                    label: 'Confirm Schedule',
                    icon: Icons.send_outlined,
                    onPressed: _confirm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFC8E0FF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const PersonAvatar(
                initials: 'RV',
                color: Color(0xFFB9DCE8),
                radius: 27,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tutor',
                      style: TextStyle(
                        color: SkillColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Rohan Verma',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.swap_horiz,
                color: SkillColors.primary,
                size: 30,
              ),
              const SizedBox(width: 10),
              PersonAvatar(
                initials: widget.tutor.initials,
                color: widget.tutor.avatarColor,
                radius: 27,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Learner',
                      style: TextStyle(
                        color: SkillColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      widget.tutor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          const Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                color: SkillColors.primary,
                size: 27,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skill / Topic',
                      style: TextStyle(
                        color: SkillColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'UI/UX Basics',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Learn the basics of UI/UX design.',
                      style: TextStyle(
                        color: SkillColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SoftTag(label: 'Online', icon: Icons.computer_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _choice(
    String label,
    bool selected,
    VoidCallback onTap, {
    bool compact = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: BoxConstraints(minHeight: compact ? 42 : 62),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 8,
          vertical: compact ? 7 : 9,
        ),
        decoration: BoxDecoration(
          color: selected ? SkillColors.primary : Colors.white,
          border: Border.all(color: SkillColors.primary),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : SkillColors.navy,
              fontSize: compact ? 11 : 12.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _platformChoice(String platform, IconData icon) {
    final selected = _platform == platform;
    return InkWell(
      onTap: () => setState(() => _platform = platform),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 78,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4F8FF) : Colors.white,
          border: Border.all(
            color: selected ? SkillColors.primary : SkillColors.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: SkillColors.primary, size: 27),
            const SizedBox(height: 5),
            Text(
              platform,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: selected ? SkillColors.primary : SkillColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    _store.addScheduledSession(
      tutor: widget.tutor,
      date: _dates[_selectedDate],
      time: '$_selectedTime – ${_endTime(_selectedTime, _duration)}',
      platform: _platform,
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => MySessionsScreen(store: _store)),
      (route) => route.isFirst,
    );
  }

  String _endTime(String start, int minutes) {
    final parts = start.split(RegExp(r'[: ]'));
    var hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final pm = parts[2] == 'PM';
    if (pm && hour != 12) hour += 12;
    final value = DateTime(
      2025,
      1,
      1,
      hour,
      minute,
    ).add(Duration(minutes: minutes));
    final outputHour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    return '$outputHour:${value.minute.toString().padLeft(2, '0')} ${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}
