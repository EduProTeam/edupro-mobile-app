import 'package:flutter/material.dart';

import '../../services/post_service.dart';

class PostLikeButton extends StatefulWidget {
  const PostLikeButton({
    super.key,
    required this.likeCount,
    required this.isLiked,
    required this.onLike,
  });

  final int likeCount;
  final bool isLiked;
  final Future<void> Function(bool liked) onLike;

  @override
  State<PostLikeButton> createState() => _PostLikeButtonState();
}

class _PostLikeButtonState extends State<PostLikeButton> {
  bool _saving = false;
  bool? _pendingLiked;

  @override
  void didUpdateWidget(covariant PostLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_saving && widget.isLiked == _pendingLiked) {
      _pendingLiked = null;
    }
  }

  Future<void> _like() async {
    if (_saving) return;
    final previousLiked = _pendingLiked ?? widget.isLiked;
    final liked = !previousLiked;
    setState(() {
      _saving = true;
      _pendingLiked = liked;
    });
    try {
      await widget.onLike(liked);
      if (mounted && widget.isLiked == liked) {
        setState(() => _pendingLiked = null);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _pendingLiked = widget.isLiked == previousLiked
              ? null
              : previousLiked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is PostFailure
                  ? error.message
                  : 'Unable to update like. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liked = _pendingLiked ?? widget.isLiked;
    // Adjust immediately, then use the feed count once its state catches up.
    final count =
        (widget.likeCount + (liked == widget.isLiked ? 0 : (liked ? 1 : -1)))
            .clamp(0, 0x7FFFFFFFFFFFFFFF);
    final color = liked ? const Color(0xFF5B2CCF) : const Color(0xFF1E1E1E);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: liked ? 'Unlike post' : 'Like post',
          onPressed: _saving ? null : _like,
          icon: Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            color: color,
          ),
        ),
        Text('$count', style: TextStyle(color: color)),
      ],
    );
  }
}
