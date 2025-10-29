import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/review.dart';
import '../providers/review_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/url_helper.dart';

/// Widget hiển thị đánh giá với chức năng reply
///
/// [review] - Dữ liệu đánh giá
/// [onReply] - Callback khi reply thành công
/// [onSubmitted] - Callback khi submit thành công
class ReviewWidget extends StatefulWidget {
  final Review review;
  final VoidCallback? onReply;
  final VoidCallback? onSubmitted;

  const ReviewWidget({
    Key? key,
    required this.review,
    this.onReply,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<ReviewWidget> createState() => _ReviewWidgetState();
}

class _ReviewWidgetState extends State<ReviewWidget> {
  bool _showReplyForm = false;
  bool _showReplies = false;
  bool _isSubmittingReply = false;
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

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

    print('ReviewWidget: Replying to review ID: ${widget.review.id}');
    print('ReviewWidget: Review data: ${widget.review.toJson()}');

    final success = await reviewProvider.replyToReview(
      widget.review.id,
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
            content: Text(reviewProvider.error ?? 'Có lỗi xảy ra'),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and rating
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue,
                  backgroundImage: widget.review.userAvatarUrl != null
                      ? NetworkImage(UrlHelper.convertUrlForEmulator(
                          widget.review.userAvatarUrl!))
                      : null,
                  child: widget.review.userAvatarUrl == null
                      ? Text(
                          widget.review.userName.isNotEmpty
                              ? widget.review.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // User info and rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.review.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Star rating - only show for main reviews, not replies
                          if (widget.review.rating > 0) ...[
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < widget.review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.review.rating.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        widget.review.timeAgo,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Review content
            Text(
              widget.review.comment,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
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
                  ),
                ),
                if (widget.review.replies.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          _showReplies = !_showReplies;
                        });
                      }
                    },
                    icon: Icon(
                      _showReplies ? Icons.expand_less : Icons.expand_more,
                      size: 14,
                    ),
                    label: Text('${widget.review.replies.length} trả lời'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
              ],
            ),
            // Reply form
            if (_showReplyForm) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _replyController,
                      decoration: const InputDecoration(
                        hintText: 'Viết trả lời...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
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
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSubmittingReply ? null : _submitReply,
                          child: _isSubmittingReply
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Gửi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            // Replies
            if (_showReplies && widget.review.replies.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.only(left: 16),
                child: Column(
                  children: widget.review.replies.map((reply) {
                    return ReviewWidget(
                      review: reply,
                      onSubmitted: widget.onSubmitted,
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Review form widget
class ReviewFormWidget extends StatefulWidget {
  final int movieId;
  final VoidCallback? onSubmitted;

  const ReviewFormWidget({
    Key? key,
    required this.movieId,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<ReviewFormWidget> createState() => _ReviewFormWidgetState();
}

class _ReviewFormWidgetState extends State<ReviewFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 0.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')),
      );
      return;
    }

    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isSubmitting = true;
      });
    }

    final success = await reviewProvider.createReview(
      widget.movieId,
      _rating,
      _commentController.text.trim(),
      token,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }

    if (success) {
      // Clear controller safely
      try {
        if (mounted && !_commentController.hasListeners) {
          _commentController.clear();
        }
      } catch (e) {
        // Controller already disposed, ignore
      }
      widget.onSubmitted?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đánh giá đã được gửi thành công!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reviewProvider.error ?? 'Có lỗi xảy ra'),
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
              const Text(
                'Viết đánh giá',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Star rating
              Row(
                children: [
                  const Text('Đánh giá: '),
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            _rating = (index + 1).toDouble();
                          });
                        },
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0)
                    Text(
                      ' $_rating/5',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Comment field
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Viết bình luận về phim...',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Gửi đánh giá'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
