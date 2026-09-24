import 'package:flutter/material.dart';

import '../../models/skill_models.dart';
import '../../services/skill_sharing_store.dart';
import '../widgets/skill_ui.dart';
import 'my_sessions_screen.dart';
import 'offer_acceptance_screen.dart';

enum _RequestFilter { all, newest, recommended }

class SkillRequestsScreen extends StatefulWidget {
  const SkillRequestsScreen({super.key, this.store});

  final SkillSharingStore? store;

  @override
  State<SkillRequestsScreen> createState() => _SkillRequestsScreenState();
}

class _SkillRequestsScreenState extends State<SkillRequestsScreen> {
  late final SkillSharingStore _store =
      widget.store ?? SkillSharingStore.instance;
  final _searchController = TextEditingController();
  _RequestFilter _filter = _RequestFilter.all;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _store.addListener(_refresh);
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  List<SkillRequest> get _visibleRequests {
    var items = _store.requests.toList();
    if (_filter == _RequestFilter.recommended) {
      items = items.where((item) => item.recommended).toList();
    } else if (_filter == _RequestFilter.newest) {
      items = items.take(2).toList();
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((item) {
        return <String>[
          item.title,
          item.requester,
          item.description,
          ...item.tags,
        ].any((value) => value.toLowerCase().contains(query));
      }).toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return SkillPage(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            sliver: SliverList.separated(
              itemCount: _visibleRequests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _RequestCard(
                request: _visibleRequests[index],
                saved: _store.isSaved(_visibleRequests[index].id),
                offered: _store.hasOffered(_visibleRequests[index].id),
                onSave: () => _store.toggleSaved(_visibleRequests[index].id),
                onOffer: () => _sendOffer(_visibleRequests[index]),
              ),
            ),
          ),
          if (_visibleRequests.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('No skill requests match your search.'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Skill Requests',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Search requests',
                onPressed: () => setState(() => _searching = !_searching),
                icon: Icon(
                  _searching ? Icons.close : Icons.search,
                  color: SkillColors.primary,
                  size: 28,
                ),
              ),
              IconButton(
                tooltip: 'My sessions',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MySessionsScreen(store: _store),
                  ),
                ),
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  color: SkillColors.primary,
                  size: 27,
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: !_searching
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      key: const ValueKey('skill-search'),
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search skills or learners',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFF6F9FD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F3FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCDE3FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.group_outlined,
                    color: SkillColors.primary,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learn together. Grow together.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Explore live skill requests and share your knowledge.',
                        style: TextStyle(
                          color: SkillColors.secondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _filterButton('All', _RequestFilter.all)),
              const SizedBox(width: 10),
              Expanded(child: _filterButton('New', _RequestFilter.newest)),
              const SizedBox(width: 10),
              Expanded(
                child: _filterButton(
                  'Recommended ★',
                  _RequestFilter.recommended,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String label, _RequestFilter value) {
    final selected = _filter == value;
    return OutlinedButton(
      onPressed: () => setState(() => _filter = value),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        backgroundColor: selected ? SkillColors.primary : Colors.white,
        foregroundColor: selected ? Colors.white : SkillColors.secondary,
        side: BorderSide(
          color: selected ? SkillColors.primary : SkillColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }

  void _sendOffer(SkillRequest request) {
    _store.sendOffer(request.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Offer sent to ${request.requester}'),
          action: SnackBarAction(
            label: 'VIEW OFFERS',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => OfferAcceptanceScreen(store: _store),
              ),
            ),
          ),
        ),
      );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.saved,
    required this.offered,
    required this.onSave,
    required this.onOffer,
  });

  final SkillRequest request;
  final bool saved;
  final bool offered;
  final VoidCallback onSave;
  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) {
    return SkillCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PersonAvatar(
                initials: request.initials,
                color: request.avatarColor,
                radius: 27,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requester,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.role,
                      style: const TextStyle(
                        color: SkillColors.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    request.postedAgo,
                    style: const TextStyle(
                      color: SkillColors.secondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: saved ? 'Remove saved request' : 'Save request',
                    onPressed: onSave,
                    icon: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_border,
                      color: saved
                          ? SkillColors.primary
                          : SkillColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 70),
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
                const SizedBox(height: 4),
                Text(
                  request.description,
                  style: const TextStyle(
                    color: SkillColors.secondary,
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: request.tags
                      .map((tag) => SoftTag(label: tag))
                      .toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 25, color: SkillColors.border),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 390;
              return Row(
                children: [
                  Expanded(
                    child: LabeledIconInfo(
                      icon: Icons.calendar_today_outlined,
                      label: 'Preferred Date',
                      value: formatSkillDate(request.date),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LabeledIconInfo(
                      icon: Icons.schedule,
                      label: 'Preferred Time',
                      value: request.time,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 8),
                    const Expanded(
                      child: LabeledIconInfo(
                        icon: Icons.computer_outlined,
                        label: 'Mode',
                        value: 'Online',
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: BlueButton(
                  label: saved ? 'Saved' : 'Save',
                  icon: saved ? Icons.bookmark : Icons.bookmark_border,
                  outlined: true,
                  compact: true,
                  onPressed: onSave,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BlueButton(
                  label: offered ? 'Offer Sent' : 'Send Offer',
                  icon: offered ? Icons.check : Icons.send_outlined,
                  compact: true,
                  onPressed: offered ? null : onOffer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
