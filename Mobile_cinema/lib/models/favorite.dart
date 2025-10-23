class Favorite {
  final int id;
  final int userId;
  final String userEmail;
  final String movieId;
  final String title;
  final String posterUrl;
  final DateTime createdAt;

  Favorite({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.movieId,
    required this.title,
    required this.posterUrl,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'],
      userId: json['user_id'],
      userEmail: json['user_email'],
      movieId: json['movie_id'].toString(),
      title: json['title'],
      posterUrl: json['poster_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_email': userEmail,
      'movie_id': movieId,
      'title': title,
      'poster_url': posterUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class FavoritesResponse {
  final bool success;
  final String? message;
  final List<Favorite> favorites;
  final int? total;
  final int? currentPage;
  final int? perPage;
  final int? lastPage;

  FavoritesResponse({
    required this.success,
    this.message,
    required this.favorites,
    this.total,
    this.currentPage,
    this.perPage,
    this.lastPage,
  });

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) {
    List<Favorite> favoritesList = [];

    if (json['data'] is List) {
      // Trường hợp data là array trực tiếp
      favoritesList = (json['data'] as List)
          .map((favoriteJson) => Favorite.fromJson(favoriteJson))
          .toList();
    } else if (json['data'] is Map && json['data']['data'] is List) {
      // Trường hợp data có pagination
      favoritesList = (json['data']['data'] as List)
          .map((favoriteJson) => Favorite.fromJson(favoriteJson))
          .toList();
    }

    return FavoritesResponse(
      success: json['success'],
      message: json['message'],
      favorites: favoritesList,
      total: json['data']?['total'],
      currentPage: json['data']?['current_page'],
      perPage: json['data']?['per_page'],
      lastPage: json['data']?['last_page'],
    );
  }
}
