import 'package:flutter/material.dart';

import '../../models/skill_models.dart';
import '../../services/skill_sharing_store.dart';
import '../widgets/skill_ui.dart';

class PublishMeetingLinkScreen extends StatefulWidget {
  const PublishMeetingLinkScreen({
    super.key,
    required this.session,
    this.store,
  });

  final SkillSession session;
  final SkillSharingStore? store;

  @override
  State<PublishMeetingLinkScreen> createState() =>
      _PublishMeetingLinkScreenState();
}

class _PublishMeetingLinkScreenState extends State<PublishMeetingLinkScreen> {
  late final SkillSharingStore _store =
      widget.store ?? SkillSharingStore.instance;
  final _formKey = GlobalKey<FormState>();
  late final _linkController = TextEditingController(
    text:
        widget.session.meetingLink ?? 'https://zoom.us/j/9876543210?pwd=abc123',
  );
  final _idController = TextEditingController(text: '987 654 3210');
  final _passcodeController = TextEditingController(text: '123456');
  late final _messageController = TextEditingController(
    text:
        'Hi ${widget.session.person.split(' ').first}, here is the meeting link for our session. See you then!',
  );
  String _platform = 'Zoom';
  bool _obscurePasscode = true;
  bool _notify = true;

  @override
  void dispose() {
    _linkController.dispose();
    _idController.dispose();
    _passcodeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SkillPage(
      appBar: const SkillAppBar(
        title: 'Publish Meeting Link',
        subtitle: 'Share meeting details with your learner',
      ),
      safeTop: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            SkillCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      PersonAvatar(
                        initials: widget.session.initials,
                        color: widget.session.avatarColor,
                        radius: 27,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.session.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            Text(
                              widget.session.person,
                              style: const TextStyle(
                                color: SkillColors.secondary,
                                fontSize: 14,
                              ),
                            ),
                            const Text(
                              'Student',
                              style: TextStyle(
                                color: SkillColors.secondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SoftTag(
                        label: 'Scheduled',
                        icon: Icons.calendar_today_outlined,
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
                          value: formatSkillDate(widget.session.date),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: LabeledIconInfo(
                          icon: Icons.schedule,
                          label: 'Time',
                          value: widget.session.time,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: LabeledIconInfo(
                          icon: Icons.computer_outlined,
                          label: 'Mode',
                          value: 'Online',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SkillCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFFE6F1FF),
                        child: Icon(Icons.link, color: SkillColors.primary),
                      ),
                      SizedBox(width: 11),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meeting Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Add your meeting link and details below.',
                            style: TextStyle(
                              color: SkillColors.secondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  const Text(
                    'Meeting Platform',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _platform,
                    items: const ['Zoom', 'Google Meet', 'Microsoft Teams']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _platform = value ?? _platform),
                    decoration: _fieldDecoration(Icons.videocam_outlined),
                  ),
                  const SizedBox(height: 13),
                  _labeledField(
                    'Meeting Link (URL)',
                    _linkController,
                    Icons.link,
                    validator: (value) {
                      final uri = Uri.tryParse(value ?? '');
                      return uri != null && uri.hasScheme && uri.host.isNotEmpty
                          ? null
                          : 'Enter a valid meeting URL';
                    },
                  ),
                  const SizedBox(height: 13),
                  _labeledField(
                    'Meeting ID',
                    _idController,
                    Icons.person_outline,
                    validator: _required,
                  ),
                  const SizedBox(height: 13),
                  _labeledField(
                    'Passcode (Optional)',
                    _passcodeController,
                    Icons.lock_outline,
                    obscure: _obscurePasscode,
                    suffix: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePasscode = !_obscurePasscode),
                      icon: Icon(
                        _obscurePasscode
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Message to Learner (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _messageController,
                    maxLength: 300,
                    maxLines: 3,
                    decoration: _fieldDecoration(null),
                  ),
                  SwitchListTile.adaptive(
                    value: _notify,
                    onChanged: (value) => setState(() => _notify = value),
                    activeTrackColor: SkillColors.primary,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Notify learner instantly',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Send a notification with meeting details right away.',
                      style: TextStyle(
                        fontSize: 12,
                        color: SkillColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Learner will receive this',
                          style: TextStyle(
                            color: SkillColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            PersonAvatar(
                              initials: widget.session.initials,
                              color: widget.session.avatarColor,
                              radius: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.session.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Your meeting link for ${formatSkillDate(widget.session.date)} is ready. Tap to join.',
                                    style: const TextStyle(
                                      color: SkillColors.secondary,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          children: [
                            const SoftTag(
                              label: 'Join Meeting',
                              icon: Icons.link,
                            ),
                            SoftTag(
                              label: _platform,
                              icon: Icons.computer_outlined,
                            ),
                            SoftTag(
                              label: 'Passcode: ${_passcodeController.text}',
                              icon: Icons.lock_outline,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const InfoBanner(
                    text:
                        'Only shared with confirmed participants. Your link is secure.',
                    green: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: BlueButton(
                    label: 'Save Draft',
                    icon: Icons.description_outlined,
                    outlined: true,
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Meeting details saved as a draft.'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BlueButton(
                    label: 'Publish Link',
                    icon: Icons.send_outlined,
                    onPressed: _publish,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _labeledField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: _fieldDecoration(icon).copyWith(
            suffixIcon:
                suffix ??
                const Icon(
                  Icons.check_circle_outline,
                  color: SkillColors.green,
                ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(IconData? icon) {
    return InputDecoration(
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: SkillColors.secondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: SkillColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: SkillColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: SkillColors.primary, width: 1.5),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  void _publish() {
    if (!_formKey.currentState!.validate()) return;
    _store.publishMeetingLink(
      sessionId: widget.session.id,
      platform: _platform,
      link: _linkController.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _notify
              ? 'Meeting link published and learner notified.'
              : 'Meeting link published.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }
}
