import 'package:flutter/material.dart';

import '../models/group_model.dart';
import '../services/group_service.dart';
import 'chat_room_screen.dart';
import 'create_group_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final GroupService _groupService = GroupService();

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryBlue = Color(0xFF3D8FEF);

  static const Color backgroundColor = Color(0xFFF6F7FB);

  static const Color borderColor = Color(0xFFD9DEE7);

  static const Color darkText = Color(0xFF151A24);

  static const Color secondaryText = Color(0xFF8A94A6);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            const SizedBox(height: 12),

            // Search
            _buildSearchSection(),

            // Categories
            _buildCategories(),

            const SizedBox(height: 12),

            // AI Tutor
            _buildAiTutorButton(),

            const SizedBox(height: 20),

            // Groups title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Groups',
                  style: TextStyle(
                    color: darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Groups
            Expanded(child: _buildGroupList()),

            // Create Group
            _buildCreateGroupButton(),

            const SizedBox(height: 10),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              // Menu logic can be added later
            },
            icon: const Icon(Icons.menu_rounded, color: darkText, size: 27),
          ),

          const Expanded(
            child: Text(
              'Chat Groups',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkText,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          IconButton(
            onPressed: () {
              // Notification page can be added later
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: darkText,
              size: 27,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _searchController,

                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },

                decoration: const InputDecoration(
                  hintText: 'Search study groups...',

                  hintStyle: TextStyle(color: secondaryText, fontSize: 14),

                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: secondaryText,
                    size: 23,
                  ),

                  border: InputBorder.none,

                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: IconButton(
              onPressed: () {
                // Advanced filter can be added later
              },
              icon: const Icon(Icons.tune_rounded, color: darkText),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY LIST
  // Categories come from GroupService / Firebase
  // ============================================================

  Widget _buildCategories() {
    return SizedBox(
      height: 60,

      child: StreamBuilder<List<String>>(
        stream: _groupService.getCategories(),

        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: LinearProgressIndicator(color: primaryBlue)),
            );
          }

          // Error
          if (snapshot.hasError) {
            return const SizedBox.shrink();
          }

          final firebaseCategories = snapshot.data ?? [];

          // "All" is a UI filter option
          final categories = <String>['All', ...firebaseCategories];

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            itemCount: categories.length,
            separatorBuilder: (_, __) {
              return const SizedBox(width: 8);
            },
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategory == category;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected ? primaryBlue : const Color(0xFF949BA6),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : darkText,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // AI TUTOR
  // UI PLACEHOLDER ONLY
  // ============================================================

  Widget _buildAiTutorButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),

      child: Material(
        color: Colors.white,

        borderRadius: BorderRadius.circular(14),

        child: InkWell(
          borderRadius: BorderRadius.circular(14),

          onTap: () {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('AI Tutor will be added later.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
          },

          child: Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),

              border: Border.all(color: const Color(0xFFABB4C4)),
            ),

            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,

                  decoration: BoxDecoration(
                    shape: BoxShape.circle,

                    color: primaryBlue.withValues(alpha: 0.08),

                    border: Border.all(
                      color: primaryBlue.withValues(alpha: 0.25),
                    ),
                  ),

                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: primaryBlue,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'AI Tutor Bot',

                        style: TextStyle(
                          color: darkText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      SizedBox(height: 3),

                      Text(
                        'Ask any math or physics question instantly...',

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(color: secondaryText, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: secondaryText,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GROUP LIST
  // Filtering logic is now inside GroupService
  // ============================================================

  Widget _buildGroupList() {
    return StreamBuilder<List<GroupModel>>(
      stream: _groupService.getFilteredGroups(
        searchQuery: _searchQuery,
        category: _selectedCategory,

        // true = only current user's groups
        // false = all groups
        onlyMyGroups: false,
      ),

      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }

        // Error
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Text(
                'Could not load groups.\n${snapshot.error}',

                textAlign: TextAlign.center,

                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        }

        final groups = snapshot.data ?? [];

        // Empty
        if (groups.isEmpty) {
          return const Center(
            child: Text(
              'No groups found.',

              style: TextStyle(color: secondaryText, fontSize: 14),
            ),
          );
        }

        // List
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),

          itemCount: groups.length,

          separatorBuilder: (_, __) {
            return const SizedBox(height: 10);
          },

          itemBuilder: (context, index) {
            final group = groups[index];

            return _buildGroupCard(group);
          },
        );
      },
    );
  }

  // ============================================================
  // GROUP CARD
  // ============================================================

  Widget _buildGroupCard(GroupModel group) {
    return Material(
      color: Colors.white,

      borderRadius: BorderRadius.circular(14),

      child: InkWell(
        borderRadius: BorderRadius.circular(14),

        // Open Chat Room
        onTap: () {
          _openGroup(group);
        },

        child: Container(
          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),

            border: Border.all(color: borderColor),
          ),

          child: Row(
            children: [
              // Image
              GestureDetector(
                onTap: () {
                  _handleGroupIconTap(group);
                },
                child: _buildGroupAvatar(group),
              ),

              const SizedBox(width: 12),

              // Group details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      group.groupName,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      group.description,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${group.members.length} members',

                      style: const TextStyle(
                        color: Color(0xFFA0A8B5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Category + arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,

                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),

                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.07),

                      borderRadius: BorderRadius.circular(14),

                      border: Border.all(
                        color: primaryBlue.withValues(alpha: 0.35),
                      ),
                    ),

                    child: Text(
                      group.category,

                      style: const TextStyle(
                        color: Color(0xFF68758A),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: secondaryText,
                    size: 22,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GROUP Open
  // ============================================================

  Future<void> _openGroup(GroupModel group) async {
    final isMember = _groupService.isCurrentUserMember(group);

    // Already member
    if (isMember) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatRoomScreen(group: group)),
      );
      return;
    }

    // Not a member -> ask to join
    final shouldJoin = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            group.groupName,
            style: const TextStyle(
              color: Color(0xFF151A24),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'You need to join this group before you can chat.',
            style: TextStyle(
              color: Color(0xFF8A94A6),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7A8494),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D8FEF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Join Group',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (shouldJoin != true) {
      return;
    }

    try {
      await _groupService.joinGroup(group.id!);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You joined the group successfully.')),
      );

      // Join successful -> now allow chat
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatRoomScreen(group: group)),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to join group: $e')));
    }
  }

  // ============================================================
  // GROUP handle
  // ============================================================

  Future<void> _handleGroupIconTap(GroupModel group) async {
    final isMember = _groupService.isCurrentUserMember(group);

    // Already member nam chat room ekata yanna
    if (isMember) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatRoomScreen(group: group)),
      );
      return;
    }

    // Member newei nam join dialog eka pennanna
    final shouldJoin = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Join ${group.groupName}?'),
          content: const Text('Join this group to participate in the chat.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Join Group'),
            ),
          ],
        );
      },
    );

    if (shouldJoin != true) {
      return;
    }

    await _groupService.joinGroup(group.id!);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You joined the group successfully.')),
    );
  }

  // ============================================================
  // GROUP IMAGE
  // ============================================================

  Widget _buildGroupAvatar(GroupModel group) {
    if (group.imageUrl.trim().isEmpty) {
      return _defaultGroupAvatar();
    }

    return ClipOval(
      child: Image.network(
        group.imageUrl,

        width: 46,
        height: 46,

        fit: BoxFit.cover,

        errorBuilder: (context, error, stackTrace) {
          return _defaultGroupAvatar();
        },
      ),
    );
  }

  Widget _defaultGroupAvatar() {
    return Container(
      width: 46,
      height: 46,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        color: primaryBlue.withValues(alpha: 0.06),

        border: Border.all(color: const Color(0xFFACB6C7)),
      ),

      child: const Icon(
        Icons.person_outline_rounded,
        color: Color(0xFF748095),
        size: 23,
      ),
    );
  }

  // ============================================================
  // CREATE GROUP BUTTON
  // ============================================================

  Widget _buildCreateGroupButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),

      child: SizedBox(
        width: double.infinity,
        height: 50,

        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
            );
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,

            foregroundColor: Colors.white,

            elevation: 0,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          child: const Text(
            'Create Group',

            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // UI ONLY FOR NOW
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,

        border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
      ),

      child: BottomNavigationBar(
        currentIndex: 1,

        type: BottomNavigationBarType.fixed,

        backgroundColor: Colors.white,

        elevation: 0,

        selectedItemColor: primaryBlue,

        unselectedItemColor: const Color(0xFFA6AFBD),

        selectedFontSize: 11,
        unselectedFontSize: 11,

        showUnselectedLabels: true,

        onTap: (index) {
          // Bottom navigation logic later
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.memory_outlined),
            activeIcon: Icon(Icons.memory_rounded),
            label: 'Skills',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.insert_drive_file_outlined),
            activeIcon: Icon(Icons.insert_drive_file_rounded),
            label: 'Files',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
