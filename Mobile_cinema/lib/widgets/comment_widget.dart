import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/comment.dart';
import '../providers/comment_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/url_helper.dart';

/// Widget hiển thị bình luận với chức năng reply
///
/// [comment] - Dữ liệu bình luận
/// [onReply] - Callback khi reply thành công
class CommentWidget extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onReply;

  const CommentWidget({
    Key? key,
    required this.comment,
    this.onReply,
  }) : super(key: key);

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  bool _showReplies = false;
  bool _showReplyForm = false;
  final _replyController = TextEditingController();
  bool _isSubmittingReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final commentProvider =
        Provider.of<CommentProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để trả lời')),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSubmittingReply = true;
      });
    }

    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để trả lời')),
      );
      return;
    }

    final success = await commentProvider.replyToComment(
      widget.comment.id,
      _replyController.text.trim(),
      token,
    );

    if (mounted) {
      setState(() {
        _isSubmittingReply = false;
      });
    }

    if (success) {
      // Clear controller safely
      try {
        if (mounted && !_replyController.hasListeners) {
          _replyController.clear();
        }
      } catch (e) {
        // Controller already disposed, ignore
      }
      if (mounted) {
        setState(() {
          _showReplyForm = false;
          _showReplies = true;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trả lời đã được gửi thành công!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(commentProvider.error ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        vertical: 4,
        horizontal: widget.comment.isReply ? 32 : 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  backgroundImage: widget.comment.avatarUrl.isNotEmpty
                      ? NetworkImage(UrlHelper.convertUrlForEmulator(
                          widget.comment.avatarUrl))
                      : null,
                  child: widget.comment.avatarUrl.isEmpty
                      ? Text(
                          widget.comment.displayName.isNotEmpty
                              ? widget.comment.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // User name
                Expanded(
                  child: Text(
                    widget.comment.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Time ago
                Text(
                  widget.comment.timeAgo,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Comment content
            if (widget.comment.isHidden)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility_off,
                        color: Colors.red[600], size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Nội dung này đã bị ẩn do vi phạm',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                widget.comment.content,
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 8),

            // Display replies if any
            if (widget.comment.replies.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Show/Hide replies button
              TextButton.icon(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _showReplies = !_showReplies;
                    });
                  }
                },
                icon: Icon(
                  _showReplies
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                ),
                label: Text(
                  _showReplies
                      ? 'Ẩn ${widget.comment.replies.length} trả lời'
                      : 'Xem ${widget.comment.replies.length} trả lời',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                ),
              ),

              // Replies list
              if (_showReplies) ...[
                const SizedBox(height: 8),
                ...widget.comment.replies.map((reply) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: CommentWidget(
                        comment: reply,
                        onReply: widget.onReply,
                      ),
                    )),
              ],
            ],

            // Action buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _showReplyForm = !_showReplyForm;
                      });
                    }
                  },
                  icon: const Icon(Icons.reply, size: 14),
                  label: const Text('Trả lời'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 32),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement like functionality
                  },
                  icon: const Icon(Icons.thumb_up_outlined, size: 14),
                  label: const Text('Thích'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
            // Reply form
            if (_showReplyForm) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      decoration: const InputDecoration(
                        hintText: 'Viết trả lời...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      IconButton(
                        onPressed: _isSubmittingReply ? null : _submitReply,
                        icon: _isSubmittingReply
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (mounted) {
                            setState(() {
                              _showReplyForm = false;
                            });
                            // Clear controller safely
                            try {
                              if (mounted && !_replyController.hasListeners) {
                                _replyController.clear();
                              }
                            } catch (e) {
                              // Controller already disposed, ignore
                            }
                          }
                        },
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CommentFormWidget extends StatefulWidget {
  final int movieId;
  final int? parentId;
  final VoidCallback? onSubmitted;

  const CommentFormWidget({
    Key? key,
    required this.movieId,
    this.parentId,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<CommentFormWidget> createState() => _CommentFormWidgetState();
}

class _CommentFormWidgetState extends State<CommentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final commentProvider =
        Provider.of<CommentProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để bình luận')),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSubmitting = true;
      });
    }

    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để bình luận')),
      );
      return;
    }

    final success = await commentProvider.createComment(
      widget.movieId,
      _commentController.text.trim(),
      parentId: widget.parentId,
      token: token,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }

    if (success) {
      // Clear controller safely
      try {
        if (mounted) {
          _commentController.clear();
        }
      } catch (e) {
        // Controller already disposed, ignore
      }
      widget.onSubmitted?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bình luận đã được gửi thành công!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(commentProvider.error ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.parentId != null
                    ? 'Trả lời bình luận'
                    : 'Viết bình luận',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Comment input
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Bình luận của bạn',
                  hintText: 'Chia sẻ suy nghĩ về bộ phim...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập bình luận';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.parentId != null
                          ? 'Gửi trả lời'
                          : 'Gửi bình luận'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
