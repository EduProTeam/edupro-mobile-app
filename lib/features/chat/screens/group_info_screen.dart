import 'package:flutter/material.dart';

import '../models/group_model.dart';
import '../models/group_member_model.dart';
import '../services/group_service.dart';
import 'group_list_screen.dart';

class GroupInfoScreen extends StatefulWidget {
  final GroupModel group;

  const GroupInfoScreen({super.key, required this.group});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final GroupService _groupService = GroupService();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCategory;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isExiting = false;
  bool _isDeleting = false;

  static const Color primaryBlue = Color(0xFF3D8FEF);
  static const Color backgroundColor = Color(0xFFF6F7FB);
  static const Color darkText = Color(0xFF151A24);
  static const Color secondaryText = Color(0xFF7A8494);
  static const Color borderColor = Color(0xFFD9DEE7);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _nameController.text = widget.group.groupName;
    _descriptionController.text = widget.group.description;
    _selectedCategory = widget.group.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // SYNC FORM
  // ============================================================

  void _syncForm(GroupModel group) {
    if (_isEditing) {
      return;
    }

    _nameController.text = group.groupName;
    _descriptionController.text = group.description;
    _selectedCategory = group.category;
  }

  // ============================================================
  // UPDATE GROUP
  // ============================================================

  Future<void> _updateGroup(GroupModel group) async {
    if (_nameController.text.trim().isEmpty) {
      _showMessage('Please enter a group name.');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showMessage('Please enter a description.');
      return;
    }

    if (_selectedCategory == null) {
      _showMessage('Please select a category.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _groupService.updateGroupDetails(
        groupId: group.id!,
        groupName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
      });

      _showMessage('Group updated successfully.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Failed to update group: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // EXIT GROUP
  // ============================================================

  Future<void> _exitGroup(GroupModel group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Exit Group?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text('Are you sure you want to exit ${group.groupName}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              style: TextButton.styleFrom(foregroundColor: secondaryText),
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
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Exit Group',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      _isExiting = true;
    });

    try {
      await _groupService.exitGroup(group.id!);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GroupListScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Failed to exit group: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isExiting = false;
        });
      }
    }
  }

  // ============================================================
  // DELETE GROUP
  // ============================================================

  Future<void> _deleteGroup(GroupModel group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Group?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Are you sure you want to permanently delete ${group.groupName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              style: TextButton.styleFrom(foregroundColor: secondaryText),
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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _groupService.deleteGroup(group.id!);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GroupListScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Failed to delete group: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ============================================================
  // INITIALS
  // Sahan Dilhara -> SD
  // Kasun Perera -> KP
  // ============================================================

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      final value = parts.first;

      if (value.length >= 2) {
        return value.substring(0, 2).toUpperCase();
      }

      return value.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // ============================================================
  // MAKE MEMBER ADMIN
  // ============================================================

  Future<void> _makeAdmin(GroupModel group, GroupMemberModel member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Make Admin?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Do you want to make ${member.fullName} an admin of this group?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              style: TextButton.styleFrom(foregroundColor: secondaryText),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Make Admin',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await _groupService.makeMemberAdmin(
        groupId: group.id!,
        memberId: member.uid,
      );

      if (!mounted) {
        return;
      }

      _showMessage('${member.fullName} is now an admin.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Failed to make admin: $e');
    }
  }

  // ============================================================
  // MEMBERS LIST
  // ============================================================

  Widget _buildMembersList(GroupModel group, bool currentUserIsAdmin) {
    return FutureBuilder<List<GroupMemberModel>>(
      future: _groupService.getGroupMembers(group),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: primaryBlue),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: const Text(
              'Could not load members.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: const Text(
              'No members found.',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryText),
            ),
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: members.length,
            separatorBuilder: (_, __) {
              return const Divider(height: 1, indent: 68, color: borderColor);
            },
            itemBuilder: (context, index) {
              final member = members[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // ==========================================
                    // USER INITIALS
                    // ==========================================

                    CircleAvatar(
                      radius: 22,
                      backgroundColor: primaryBlue.withValues(alpha: 0.10),
                      child: Text(
                        _getInitials(member.fullName),
                        style: const TextStyle(
                          color: primaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ==========================================
                    // USER NAME
                    // ==========================================
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: darkText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          if (member.email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              member.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ==========================================
                    // ADMIN BADGE
                    // ==========================================
                    if (member.isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    // ==========================================
                    // MAKE ADMIN
                    // ==========================================
                    else if (currentUserIsAdmin)
                      TextButton(
                        onPressed: () {
                          _makeAdmin(group, member);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Make Admin',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GroupModel?>(
      stream: _groupService.watchGroup(widget.group.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: backgroundColor,
            body: Center(child: CircularProgressIndicator(color: primaryBlue)),
          );
        }

        final group = snapshot.data ?? widget.group;

        _syncForm(group);

        final isAdmin = _groupService.isCurrentUserAdmin(group);

        return Scaffold(
          backgroundColor: backgroundColor,

          appBar: AppBar(
            backgroundColor: backgroundColor,
            surfaceTintColor: backgroundColor,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: darkText),
            title: const Text(
              'Group Details',
              style: TextStyle(color: darkText, fontWeight: FontWeight.w800),
            ),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
            child: Column(
              children: [
                // =================================================
                // GROUP IMAGE
                // =================================================

                _buildGroupImage(group),

                const SizedBox(height: 14),

                Text(
                  group.groupName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${group.members.length} members',
                  style: const TextStyle(color: secondaryText, fontSize: 14),
                ),

                // =================================================
                // CURRENT USER ADMIN BADGE
                // =================================================
                if (isAdmin) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Admin',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // =================================================
                // GROUP DETAILS
                // =================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      // GROUP NAME

                      _buildInfoSection(
                        icon: Icons.groups_outlined,
                        title: 'Group Name',
                        child: isAdmin && _isEditing
                            ? _buildEditField(_nameController)
                            : Text(
                                group.groupName,
                                style: const TextStyle(
                                  color: secondaryText,
                                  fontSize: 14,
                                ),
                              ),
                      ),

                      const Divider(height: 28, color: borderColor),

                      // DESCRIPTION
                      _buildInfoSection(
                        icon: Icons.description_outlined,
                        title: 'Description',
                        child: isAdmin && _isEditing
                            ? _buildEditField(
                                _descriptionController,
                                maxLines: 4,
                              )
                            : Text(
                                group.description,
                                style: const TextStyle(
                                  color: secondaryText,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                      ),

                      const Divider(height: 28, color: borderColor),

                      // CATEGORY
                      _buildInfoSection(
                        icon: Icons.grid_view_outlined,
                        title: 'Category',
                        child: isAdmin && _isEditing
                            ? _buildCategoryDropdown(group)
                            : _buildCategoryChip(group.category),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // MEMBERS
                // =================================================
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Members (${group.members.length})',
                    style: const TextStyle(
                      color: darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                _buildMembersList(group, isAdmin),

                const SizedBox(height: 20),

                // =================================================
                // ADMIN EDIT / UPDATE
                // =================================================
                if (isAdmin)
                  if (!_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditing = true;

                            _nameController.text = group.groupName;

                            _descriptionController.text = group.description;

                            _selectedCategory = group.category;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text(
                          'Edit Group',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;

                                _nameController.text = group.groupName;

                                _descriptionController.text = group.description;

                                _selectedCategory = group.category;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              foregroundColor: secondaryText,
                              side: const BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    _updateGroup(group);
                                  },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 50),
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Update Group',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                if (isAdmin) const SizedBox(height: 12),

                // =================================================
                // EXIT GROUP - EVERY MEMBER
                // =================================================
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isExiting
                        ? null
                        : () {
                            _exitGroup(group);
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: _isExiting
                        ? const Text('Exiting...')
                        : const Text(
                            'Exit Group',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),

                // =================================================
                // DELETE GROUP - ADMIN ONLY
                // =================================================
                if (isAdmin) ...[
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isDeleting
                          ? null
                          : () {
                              _deleteGroup(group);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEDED),
                        foregroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: _isDeleting
                          ? const Text('Deleting...')
                          : const Text(
                              'Delete Group',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // GROUP IMAGE
  // ============================================================

  Widget _buildGroupImage(GroupModel group) {
    if (group.imageUrl.trim().isEmpty) {
      return const CircleAvatar(
        radius: 46,
        backgroundColor: Color(0xFFE8F1FD),
        child: Icon(Icons.groups_rounded, size: 42, color: primaryBlue),
      );
    }

    return ClipOval(
      child: Image.network(
        group.imageUrl,
        width: 92,
        height: 92,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const CircleAvatar(
            radius: 46,
            backgroundColor: Color(0xFFE8F1FD),
            child: Icon(Icons.groups_rounded, size: 42, color: primaryBlue),
          );
        },
      ),
    );
  }

  // ============================================================
  // INFO SECTION
  // ============================================================

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: primaryBlue),
          ),
          child: Icon(icon, color: primaryBlue, size: 21),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: darkText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 5),

              child,
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EDIT FIELD
  // ============================================================

  Widget _buildEditField(TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.all(12),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderColor),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryBlue),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY DROPDOWN
  // ============================================================

  Widget _buildCategoryDropdown(GroupModel group) {
    return StreamBuilder<List<String>>(
      stream: _groupService.getCategories(),
      builder: (context, snapshot) {
        final categories = <String>{
          group.category,
          _selectedCategory ?? group.category,
          ...(snapshot.data ?? []),
        }.toList();

        return DropdownButtonFormField<String>(
          value: _selectedCategory ?? group.category,
          isExpanded: true,

          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: borderColor),
            ),
          ),

          items: categories
              .map(
                (category) => DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                ),
              )
              .toList(),

          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // CATEGORY CHIP
  // ============================================================

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: primaryBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
