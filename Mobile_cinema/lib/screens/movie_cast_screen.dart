import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cast_provider.dart';
import '../models/cast.dart';

class MovieCastScreen extends StatefulWidget {
  final int movieId;
  final String movieTitle;

  const MovieCastScreen({
    super.key,
    required this.movieId,
    required this.movieTitle,
  });

  @override
  State<MovieCastScreen> createState() => _MovieCastScreenState();
}

class _MovieCastScreenState extends State<MovieCastScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CastProvider>().getMovieCast(widget.movieId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cast - ${widget.movieTitle}'),
        elevation: 0,
      ),
      body: Consumer<CastProvider>(
        builder: (context, castProvider, child) {
          if (castProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (castProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    castProvider.errorMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      castProvider.clearError();
                      castProvider.getMovieCast(widget.movieId);
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (castProvider.movieCast.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có thông tin cast',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Directors
                if (castProvider.directors.isNotEmpty) ...[
                  const Text(
                    'Đạo diễn',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...castProvider.directors
                      .map((director) => _buildCastCard(director)),
                  const SizedBox(height: 24),
                ],

                // Main Cast
                if (castProvider.mainCast.isNotEmpty) ...[
                  const Text(
                    'Diễn viên chính',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...castProvider.mainCast.map((cast) => _buildCastCard(cast)),
                  const SizedBox(height: 24),
                ],

                // Supporting Cast
                if (castProvider.supportingCast.isNotEmpty) ...[
                  const Text(
                    'Diễn viên phụ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...castProvider.supportingCast
                      .map((cast) => _buildCastCard(cast)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCastCard(Cast cast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[300],
            backgroundImage:
                cast.avatar != null ? NetworkImage(cast.avatar!) : null,
            child: cast.avatar == null
                ? const Icon(Icons.person, size: 30, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 16),

          // Cast info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cast.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (cast.characterName != null &&
                    cast.characterName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'as ${cast.characterName}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cast.role == 'director'
                        ? Colors.blue[100]
                        : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cast.role == 'director' ? 'Đạo diễn' : 'Diễn viên',
                    style: TextStyle(
                      fontSize: 12,
                      color: cast.role == 'director'
                          ? Colors.blue[700]
                          : Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
