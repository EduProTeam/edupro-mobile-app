import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';

class GroupInfoScreen extends StatelessWidget {
  final GroupModel group;
  const GroupInfoScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final GroupService groupService = GroupService();
    final bool isCreator = group.createdBy == groupService.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Group Info', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(group.imageUrl),
            ),
            const SizedBox(height: 16),
            Text(
              group.groupName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              'Category: ${group.category}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              group.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 30),

            // Creator Options vs Member Options
            if (isCreator) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  'Update Group Details',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  // Trigger Update Logic
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text(
                  'Delete Group',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  await groupService.deleteGroup(group.id!);
                  if (context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
              ),
            ] else ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                label: const Text(
                  'Exit Group',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  await groupService.exitGroup(group.id!);
                  if (context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
