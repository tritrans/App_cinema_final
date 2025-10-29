import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/review_provider.dart';
import '../providers/comment_provider.dart';
import 'review_widget.dart';
import 'comment_widget.dart';

class ReviewCommentSection extends StatefulWidget {
  final int movieId;

  const ReviewCommentSection({
    Key? key,
    required this.movieId,
  }) : super(key: key);

  @override
  State<ReviewCommentSection> createState() => _ReviewCommentSectionState();
}

class _ReviewCommentSectionState extends State<ReviewCommentSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    final commentProvider =
        Provider.of<CommentProvider>(context, listen: false);

    reviewProvider.getMovieReviews(widget.movieId);
    commentProvider.getMovieComments(widget.movieId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            tabs: const [
              Tab(
                icon: Icon(Icons.star),
                text: 'Đánh giá',
              ),
              Tab(
                icon: Icon(Icons.chat_bubble_outline),
                text: 'Bình luận',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildReviewsTab(),
              _buildCommentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        if (reviewProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (reviewProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  reviewProvider.error!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (reviewProvider.reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có đánh giá nào',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy là người đầu tiên đánh giá bộ phim này!',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await reviewProvider.getMovieReviews(widget.movieId);
          },
          child: ListView.builder(
            itemCount: reviewProvider.reviews.length + 1, // +1 for form
            itemBuilder: (context, index) {
              if (index == 0) {
                return ReviewFormWidget(
                  movieId: widget.movieId,
                  onSubmitted: () {
                    reviewProvider.getMovieReviews(widget.movieId);
                  },
                );
              }

              final review = reviewProvider.reviews[index - 1];
              return ReviewWidget(
                review: review,
                onReply: () {
                  // TODO: Implement reply functionality
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab() {
    return Consumer<CommentProvider>(
      builder: (context, commentProvider, child) {
        if (commentProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (commentProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  commentProvider.error!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        if (commentProvider.comments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có bình luận nào',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy là người đầu tiên bình luận về bộ phim này!',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await commentProvider.getMovieComments(widget.movieId);
          },
          child: ListView.builder(
            itemCount: commentProvider.mainComments.length + 1, // +1 for form
            itemBuilder: (context, index) {
              if (index == 0) {
                return CommentFormWidget(
                  movieId: widget.movieId,
                  onSubmitted: () {
                    commentProvider.getMovieComments(widget.movieId);
                  },
                );
              }

              final comment = commentProvider.mainComments[index - 1];
              return Column(
                children: [
                  CommentWidget(
                    comment: comment,
                    onReply: () {
                      // Show reply form for this comment
                      setState(() {
                        // This will trigger a rebuild and show reply form
                      });
                    },
                  ),
                  // Show replies
                  ...commentProvider
                      .getRepliesForComment(comment.id)
                      .map((reply) => CommentWidget(
                            comment: reply,
                            onReply: () {
                              // Show reply form for this reply
                              setState(() {
                                // This will trigger a rebuild and show reply form
                              });
                            },
                          ))
                      .toList(),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
