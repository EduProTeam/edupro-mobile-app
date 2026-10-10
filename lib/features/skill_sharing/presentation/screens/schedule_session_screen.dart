import 'package:flutter/material.dart';

import '../../models/skill_models.dart';
import '../../services/skill_sharing_store.dart';
import '../widgets/skill_ui.dart';
import 'my_sessions_screen.dart';

class ScheduleSessionScreen extends StatefulWidget {
  const ScheduleSessionScreen({
    super.key,
    required this.tutor,
    this.request,
    this.store,
  });

  final TutorOffer tutor;
  final SkillRequest? request;
  final SkillSharingStore? store;

  @override
  State<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  late final SkillSharingStore _store =
      widget.store ?? SkillSharingStore.instance;
  late final SkillRequest _request;
  final _noteController = TextEditingController();
  final _dateScrollController = ScrollController();
  late final List<DateTime> _dates;
  late final List<String> _times;
  late int _selectedDate;
  late String _selectedTime;
  int _duration = 60;
  String _platform = 'Google Meet';

  @override
  void initState() {
    super.initState();
    _request = widget.request ?? _store.requests.first;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final requestedDate = DateTime(
      _request.date.year,
      _request.date.month,
      _request.date.day,
    );
    final lastDate = requestedDate.isAfter(today.add(const Duration(days: 89)))
        ? requestedDate.add(const Duration(days: 30))
        : today.add(const Duration(days: 89));
    final dayCount = lastDate.difference(today).inDays + 1;
    _dates = List<DateTime>.generate(
      dayCount,
      (index) => today.add(Duration(days: index)),
    );
    _selectedDate = requestedDate.isBefore(today)
        ? 0
        : requestedDate.difference(today).inDays;

    final requestTimes = _timeParts(_request.time);
    _times = List<String>.generate(
      27,
      (index) => _formatMinutes(8 * 60 + index * 30),
    );
    if (requestTimes.isNotEmpty && !_times.contains(requestTimes.first)) {
      _times.add(requestTimes.first);
      _times.sort(
        (left, right) => _minutesFromLabel(
          left,
        ).compareTo(_minutesFromLabel(right)),
      );
    }
    _selectedTime = requestTimes.isNotEmpty
        ? requestTimes.first
        : _firstAvailableTime();
    if (requestTimes.length > 1) {
      final duration =
          _minutesFromLabel(requestTimes[1]) -
          _minutesFromLabel(requestTimes.first);
      if (<int>{30, 60, 90}.contains(duration)) _duration = duration;
    }
    if (!_isTimeAvailable(_selectedTime)) {
      _selectedTime = _firstAvailableTime();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dateScrollController.hasClients) return;
      _dateScrollController.jumpTo(
        (_selectedDate * 65.0).clamp(
          0.0,
          _dateScrollController.position.maxScrollExtent,
        ).toDouble(),
      );
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _dateScrollController.dispose();
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
                    controller: _dateScrollController,
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
                        onTap: () {
                          setState(() {
                            _selectedDate = index;
                            if (!_isTimeAvailable(_selectedTime)) {
                              _selectedTime = _firstAvailableTime();
                            }
                          });
                        },
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
                                _monthLabel(date.month),
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
                  itemBuilder: (context, index) {
                    final available = _isTimeAvailable(_times[index]);
                    return _choice(
                      _times[index],
                      _selectedTime == _times[index],
                      () => setState(() => _selectedTime = _times[index]),
                      compact: true,
                      enabled: available,
                    );
                  },
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
              PersonAvatar(
                initials: _request.initials,
                color: _request.avatarColor,
                radius: 27,
                imageUrl: _request.profileImageUrl,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tutor',
                      style: TextStyle(
                        color: SkillColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _request.requester,
                      style: const TextStyle(
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
                imageUrl: widget.tutor.profileImageUrl,
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
          Row(
            children: [
              const Icon(
                Icons.menu_book_outlined,
                color: SkillColors.primary,
                size: 27,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Skill / Topic',
                      style: TextStyle(
                        color: SkillColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _request.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _request.description,
                      style: const TextStyle(
                        color: SkillColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SoftTag(label: 'Online', icon: Icons.computer_outlined),
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
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: BoxConstraints(minHeight: compact ? 42 : 62),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 8,
          vertical: compact ? 7 : 9,
        ),
        decoration: BoxDecoration(
          color: selected
              ? SkillColors.primary
              : enabled
              ? Colors.white
              : const Color(0xFFF2F4F7),
          border: Border.all(
            color: enabled ? SkillColors.primary : SkillColors.border,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : enabled
                  ? SkillColors.navy
                  : SkillColors.secondary.withValues(alpha: .55),
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

  Future<void> _confirm() async {
    if (!_isTimeAvailable(_selectedTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a future date and time.'),
        ),
      );
      return;
    }
    try {
      await _store.acceptOffer(
        offer: widget.tutor,
        date: _dates[_selectedDate],
        time: '$_selectedTime – ${_endTime(_selectedTime, _duration)}',
        platform: _platform,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
      return;
    }
    if (!mounted) return;
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

  List<String> _timeParts(String value) => RegExp(
    r'\d{1,2}:\d{2}\s*(?:AM|PM)',
    caseSensitive: false,
  ).allMatches(value).map((match) => match.group(0)!.toUpperCase()).toList();

  int _minutesFromLabel(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return 0;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    if (hour == 12) hour = 0;
    if (period == 'PM') hour += 12;
    return hour * 60 + minute;
  }

  String _formatMinutes(int minutes) {
    final hour24 = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  bool _isTimeAvailable(String time) {
    final date = _dates[_selectedDate];
    final minutes = _minutesFromLabel(time);
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      minutes ~/ 60,
      minutes % 60,
    );
    return start.isAfter(DateTime.now());
  }

  String _firstAvailableTime() {
    for (final time in _times) {
      if (_isTimeAvailable(time)) return time;
    }
    if (_selectedDate < _dates.length - 1) {
      _selectedDate++;
      return _times.first;
    }
    return _times.last;
  }

  String _monthLabel(int month) => const <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}
