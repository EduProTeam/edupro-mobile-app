import 'package:flutter/material.dart';

import '../models/ai_message_model.dart';
import '../services/ai_tutor_service.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final AiTutorService _aiTutorService = AiTutorService();

  static const Color primaryBlue = Color(0xFF3D8FEF);

  static const Color backgroundColor = Color(0xFFF6F7FB);

  static const Color secondaryText = Color(0xFF8A94A6);

  bool _isLoading = false;

  final List<AiMessageModel> _messages = [
    AiMessageModel(
      text: 'Hello! 👋 I am your AI Tutor. Ask me any learning question.',
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _sendMessage() async {
    final question = _messageController.text.trim();

    if (question.isEmpty || _isLoading) {
      return;
    }

    _messageController.clear();

    setState(() {
      _messages.add(AiMessageModel(text: question, isUser: true));

      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Skip greeting message from API history
      final conversation = _messages.skip(1).toList();

      final answer = await _aiTutorService.askAi(conversation);

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(AiMessageModel(text: answer, isUser: false));
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
        ),

        title: const Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFE8F1FD),
              child: Icon(
                Icons.smart_toy_outlined,
                color: primaryBlue,
                size: 22,
              ),
            ),

            SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Tutor',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your learning assistant',
                  style: TextStyle(color: secondaryText, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFE4E7EC)),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),

              itemCount: _messages.length + (_isLoading ? 1 : 0),

              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildThinking();
                }

                final message = _messages[index];

                return _buildMessageBubble(message.text, message.isUser);
              },
            ),
          ),

          _buildMessageInput(),
        ],
      ),
    );
  }

  // ============================================================
  // THINKING
  // ============================================================

  Widget _buildThinking() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 14, right: 60),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE8F1FD),
            child: Icon(Icons.smart_toy_outlined, color: primaryBlue, size: 20),
          ),

          SizedBox(width: 8),

          Text(
            'AI is thinking...',
            style: TextStyle(color: secondaryText, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _buildMessageBubble(String text, bool isUser) {
    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14, left: 60),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
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
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 45),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE8F1FD),
            child: Icon(Icons.smart_toy_outlined, color: primaryBlue, size: 20),
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF232B36),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INPUT
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
                  hintText: 'Ask your AI Tutor...',

                  hintStyle: const TextStyle(color: Color(0xFFA6AFBD)),

                  filled: true,

                  fillColor: const Color(0xFFF8FAFC),

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: Color(0xFFD5DAE2)),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: const BorderSide(color: primaryBlue),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            SizedBox(
              width: 46,
              height: 46,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendMessage,

                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),

                child: const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
