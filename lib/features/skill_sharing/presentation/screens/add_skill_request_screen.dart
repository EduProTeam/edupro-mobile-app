import 'package:flutter/material.dart';

import '../../models/skill_models.dart';
import '../../services/skill_sharing_store.dart';
import '../widgets/skill_ui.dart';

class AddSkillRequestScreen extends StatefulWidget {
  const AddSkillRequestScreen({super.key, required this.store});

  final SkillSharingStore store;

  @override
  State<AddSkillRequestScreen> createState() =>
      _AddSkillRequestScreenState();
}

class _AddSkillRequestScreenState extends State<AddSkillRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  SkillLevel _level = SkillLevel.beginner;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SkillPage(
      appBar: const SkillAppBar(title: 'Add Skill'),
      safeTop: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            SkillCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Skill or topic'),
                  TextFormField(
                    controller: _titleController,
                    decoration: _decoration('e.g. UI/UX Basics'),
                    textInputAction: TextInputAction.next,
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  _label('What will you teach?'),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: _decoration(
                      'Describe what learners will gain from this skill',
                    ),
                    minLines: 3,
                    maxLines: 5,
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  _label('Tags'),
                  TextFormField(
                    controller: _tagsController,
                    decoration: _decoration('Design, Figma, UI/UX'),
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  _label('Level'),
                  DropdownButtonFormField<SkillLevel>(
                    initialValue: _level,
                    decoration: _decoration(null),
                    items: SkillLevel.values
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(_levelLabel(level)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _level = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  _label('Preferred date and time'),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerButton(
                          icon: Icons.calendar_today_outlined,
                          label: _date == null
                              ? 'Select date'
                              : formatSkillDate(_date!),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PickerButton(
                          icon: Icons.schedule,
                          label: _startTime == null
                              ? 'Start time'
                              : _startTime!.format(context),
                          onTap: () => _pickTime(start: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PickerButton(
                          icon: Icons.schedule,
                          label: _endTime == null
                              ? 'End time'
                              : _endTime!.format(context),
                          onTap: () => _pickTime(start: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: BlueButton(
                      label: _saving ? 'Publishing...' : 'Publish Skill',
                      icon: Icons.add_circle_outline,
                      onPressed: _saving ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    ),
  );

  InputDecoration _decoration(String? hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF6F9FD),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: SkillColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: SkillColors.border),
    ),
  );

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'This field is required'
      : null;

  String _levelLabel(SkillLevel level) =>
      '${level.name[0].toUpperCase()}${level.name.substring(1)}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final value = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (value != null && mounted) setState(() => _date = value);
  }

  Future<void> _pickTime({required bool start}) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? _startTime ?? TimeOfDay.now()),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (start) {
        _startTime = value;
      } else {
        _endTime = value;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a date, start time and end time.')),
      );
      return;
    }
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }
    final startDateTime = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    if (!startDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a future date and start time.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.store.addSkillRequest(
        title: _titleController.text,
        description: _descriptionController.text,
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList(),
        date: _date!,
        time:
            '${_startTime!.format(context)} – ${_endTime!.format(context)}',
        level: _level,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skill published.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    }
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 58),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        side: const BorderSide(color: SkillColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}
