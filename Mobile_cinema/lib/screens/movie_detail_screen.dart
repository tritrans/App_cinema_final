import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/movie.dart';
import 'trailer_player_screen.dart';
import 'movie_cast_screen.dart';
import 'movie_booking_flow_new.dart';
import '../providers/auth_provider.dart';
import '../providers/review_provider.dart';
import '../providers/comment_provider.dart'; // Import CommentProvider
import '../widgets/review_comment_section.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      reviewProvider.getMovieReviews(widget.movie.id);

      final commentProvider =
          Provider.of<CommentProvider>(context, listen: false);
      commentProvider.getMovieComments(widget.movie.id);
    });
  }

  void _refreshReviews() {
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    reviewProvider.getMovieReviews(widget.movie.id);
  }

  void _showReviewDialog() {
    final reviewController = TextEditingController();
    double userRating = 3.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Viết đánh giá'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: userRating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  userRating = rating;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  hintText: 'Nhập bình luận của bạn...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reviewProvider =
                    Provider.of<ReviewProvider>(context, listen: false);
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);

                if (!authProvider.isAuthenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vui lòng đăng nhập để đánh giá')),
                  );
                  return;
                }

                final success = await reviewProvider.createReview(
                  widget.movie.id,
                  userRating,
                  reviewController.text.isNotEmpty ? reviewController.text : '',
                  authProvider.token!,
                );

                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi đánh giá!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(reviewProvider.errorMessage ??
                            'Lỗi khi gửi đánh giá.')),
                  );
                }
              },
              child: const Text('Gửi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    widget.movie.poster,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      child: Center(
                        child: Icon(Icons.broken_image,
                            color: isDark ? Colors.grey[400] : Colors.grey,
                            size: 80),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrailerPlayerScreen(
                              movieTitle: widget.movie.title,
                              trailerUrl: widget.movie.trailer ?? '',
                            ),
                          ),
                        );
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 32),
                      ),
                      iconSize: 48,
                    ),
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: CircleAvatar(
                backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                child: Icon(Icons.arrow_back,
                    color: isDark ? Colors.white : Colors.black),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              StatefulBuilder(
                builder: (context, setStateFav) {
                  return Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      if (!authProvider.isAuthenticated) {
                        return const SizedBox.shrink();
                      }

                      // TODO: Implement favorites with new API service
                      return IconButton(
                        icon: CircleAvatar(
                          backgroundColor:
                              isDark ? Colors.grey[800] : Colors.white,
                          child: const Icon(
                            Icons.favorite_border,
                            color: Colors.red,
                          ),
                        ),
                        onPressed: () async {
                          // TODO: Implement favorite toggle with new API
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Chức năng yêu thích đang được phát triển'),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.movie.title,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              )),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text('${widget.movie.rating}/10',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Text(widget.movie.duration.toString(),
                          style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: widget.movie.genres.map((genre) {
                      return Chip(
                        label: Text(genre.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                        backgroundColor: Colors.red,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Cast button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieCastScreen(
                            movieId: widget.movie.id,
                            movieTitle: widget.movie.title,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.people, color: Colors.white),
                    label: const Text(
                      'Xem Cast',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Nội dung',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    widget.movie.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  // Reviews and Comments Section
                  _buildReviewsAndCommentsSection(isDark),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  MovieBookingFlowNew(movie: widget.movie)),
                        );
                      },
                      child: const Text('Đặt vé ngay',
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsAndCommentsSection(bool isDark) {
    return SizedBox(
      height: 500, // Fixed height for better content display
      child: ReviewCommentSection(movieId: widget.movie.id),
    );
  }

  Widget _buildReviewsTab(bool isDark) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        if (reviewProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (reviewProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Lỗi: ${reviewProvider.errorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshReviews,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        final reviews = reviewProvider.reviews;
        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có đánh giá nào',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.isAuthenticated) {
                      return ElevatedButton.icon(
                        onPressed: _showReviewDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text('Viết đánh giá đầu tiên'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      );
                    } else {
                      return ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to login
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Vui lòng đăng nhập để viết đánh giá'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Đăng nhập để đánh giá'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return _buildModernReviewCard(
              review.userName,
              review.userAvatar ?? '', // Handle nullable avatar
              review.comment ?? '', // Handle nullable comment
              review.rating,
              review.createdAt,
              isDark,
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 16),
        );
      },
    );
  }

  Widget _buildCommentsTab(bool isDark) {
    return Consumer<CommentProvider>(
      builder: (context, commentProvider, child) {
        if (commentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (commentProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Lỗi: ${commentProvider.errorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      commentProvider.getMovieComments(widget.movie.id),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        final comments = commentProvider.comments;
        if (comments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.comment_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Chưa có bình luận nào',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.isAuthenticated) {
                      return ElevatedButton.icon(
                        onPressed: _showCommentDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text('Viết bình luận đầu tiên'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      );
                    } else {
                      return ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to login
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Vui lòng đăng nhập để viết bình luận'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Đăng nhập để bình luận'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return _buildModernReviewCard(
              comment.userName,
              comment.userAvatar ?? '',
              comment.content,
              0.0, // Comments don't have a rating, pass 0.0
              comment.createdAt,
              isDark,
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 16),
        );
      },
    );
  }

  void _showCommentDialog() {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Viết bình luận'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Nhập bình luận của bạn...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final commentProvider =
                    Provider.of<CommentProvider>(context, listen: false);
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);

                if (!authProvider.isAuthenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vui lòng đăng nhập để bình luận')),
                  );
                  return;
                }

                if (commentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Bình luận không được để trống')),
                  );
                  return;
                }

                final success = await commentProvider.createComment(
                  widget.movie.id,
                  commentController.text,
                  token: authProvider.token!,
                );

                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi bình luận!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(commentProvider.errorMessage ??
                            'Lỗi khi gửi bình luận.')),
                  );
                }
              },
              child: const Text('Gửi'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModernReviewCard(String name, String imageUrl, String review,
      double rating, DateTime? createdAt, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and rating
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red[100],
                ),
                child: imageUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Name and rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Star rating (only show if rating is greater than 0)
                        if (rating > 0) ...[
                          ...List.generate(5, (index) {
                            return Icon(
                              index < rating.floor()
                                  ? Icons.star
                                  : (index < rating
                                      ? Icons.star_half
                                      : Icons.star_border),
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Time
              if (createdAt != null)
                Text(
                  _formatTimeAgo(createdAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Review content
          Text(
            review,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement reply functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chức năng trả lời đang được phát triển'),
                    ),
                  );
                },
                icon: const Icon(Icons.reply, size: 16),
                label: const Text('Trả lời'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[600],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement like functionality
                },
                icon: const Icon(Icons.thumb_up_outlined, size: 16),
                label: const Text('Thích'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
