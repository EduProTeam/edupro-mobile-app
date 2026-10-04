import 'package:flutter/material.dart';

import '../models/group_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/group_service.dart';
import 'group_info_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final GroupModel group;

  const ChatRoomScreen({super.key, required this.group});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final GroupService _groupService = GroupService();
  final TextEditingController _messageController = TextEditingController();

  static const Color primaryBlue = Color(0xFF3D8FEF);
  static const Color backgroundColor = Color(0xFFF6F7FB);
  static const Color otherMessageColor = Color(0xFFF0F3F7);
  static const Color secondaryText = Color(0xFF8A94A6);

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ============================================================
  // USER AVATAR
  // ============================================================

  Widget _buildUserAvatar(String imageUrl, String name) {
    if (imageUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(imageUrl),
      );
    }

    final firstLetter = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';

    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFE5EEF9),
      child: Text(
        firstLetter,
        style: const TextStyle(
          color: primaryBlue,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT MESSAGE TIME
  // ============================================================

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour == 0
        ? 12
        : dateTime.hour;

    final minute = dateTime.minute.toString().padLeft(2, '0');

    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    _messageController.clear();

    try {
      await _chatService.sendMessage(widget.group.id!, text);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    }
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final currentUserId = _groupService.currentUserId;

    return Scaffold(
      backgroundColor: backgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        titleSpacing: 0,

        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupInfoScreen(group: widget.group),
              ),
            );
          },

          child: Row(
            children: [
              _buildGroupAvatar(),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.groupName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '${widget.group.members.length} members',
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFE4E7EC)),

          // ====================================================
          // MESSAGES
          // ====================================================
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(widget.group.id!),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load messages.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Say Hi 👋',
                      style: TextStyle(color: secondaryText, fontSize: 14),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),

                  itemCount: messages.length,

                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    final isMe = msg.senderId == currentUserId;

                    return _buildMessageItem(msg, isMe);
                  },
                );
              },
            ),
          ),

          // ====================================================
          // MESSAGE INPUT
          // ====================================================
          _buildMessageInput(),
        ],
      ),
    );
  }

  // ============================================================
  // GROUP AVATAR
  // ============================================================

  Widget _buildGroupAvatar() {
    if (widget.group.imageUrl.trim().isEmpty) {
      return const CircleAvatar(
        radius: 20,
        backgroundColor: Color(0xFFE8F1FD),
        child: Icon(Icons.groups_rounded, color: primaryBlue, size: 22),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFE8F1FD),
      backgroundImage: NetworkImage(widget.group.imageUrl),
    );
  }

  // ============================================================
  // SINGLE MESSAGE
  // ============================================================

  Widget _buildMessageItem(MessageModel msg, bool isMe) {
    // ==========================================================
    // MY MESSAGE - RIGHT SIDE
    // ==========================================================

    if (isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14, left: 55),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: const BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              _formatTime(msg.timestamp),
              style: const TextStyle(color: secondaryText, fontSize: 10),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // OTHER MEMBER MESSAGE - LEFT SIDE
    // ==========================================================

    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 45),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // USER PROFILE PICTURE
          _buildUserAvatar(msg.senderProfileImageUrl, msg.senderName),

          const SizedBox(width: 8),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // USER NAME
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 4),
                  child: Text(
                    msg.senderName,
                    style: const TextStyle(
                      color: Color(0xFF4F5968),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // MESSAGE
                Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
                  decoration: const BoxDecoration(
                    color: otherMessageColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                      color: Color(0xFF232B36),
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // TIME UNDER MESSAGE
                Text(
                  _formatTime(msg.timestamp),
                  style: const TextStyle(color: secondaryText, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE INPUT
  // ============================================================

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
      ),

      child: SafeArea(
        top: false,

        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,

                textInputAction: TextInputAction.send,

                onSubmitted: (_) {
                  _sendMessage();
                },

                decoration: InputDecoration(
                  hintText: 'Type a message...',

                  hintStyle: const TextStyle(
                    color: Color(0xFFA6AFBD),
                    fontSize: 14,
                  ),

                  filled: true,

                  fillColor: const Color(0xFFF8FAFC),

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: Color(0xFFD5DAE2)),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: Color(0xFFD5DAE2)),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(
                      color: primaryBlue,
                      width: 1.3,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            SizedBox(
              width: 46,
              height: 46,

              child: ElevatedButton(
                onPressed: _sendMessage,

                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,

                  foregroundColor: Colors.white,

                  elevation: 0,

                  padding: EdgeInsets.zero,

                  shape: const CircleBorder(),
                ),

                child: const Icon(Icons.send_rounded, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
