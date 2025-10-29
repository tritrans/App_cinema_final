import 'genre.dart';

class Movie {
  final int id;
  final String title;
  final String? titleVi;
  final String description;
  final String? descriptionVi;
  final String poster;
  final String? backdrop;
  final String? trailer;
  final DateTime releaseDate;
  final int duration;
  final List<Genre> genres;
  final double? rating;
  final String country;
  final String language;
  final String? director;
  final List<String>? cast;
  final String slug;
  final bool featured;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Movie({
    required this.id,
    required this.title,
    this.titleVi,
    required this.description,
    this.descriptionVi,
    required this.poster,
    this.backdrop,
    this.trailer,
    required this.releaseDate,
    required this.duration,
    required this.genres,
    this.rating,
    required this.country,
    required this.language,
    this.director,
    this.cast,
    required this.slug,
    required this.featured,
    this.createdAt,
    this.updatedAt,
  });

  bool get isNowShowing => releaseDate.isBefore(DateTime.now());
  bool get isComingSoon => releaseDate.isAfter(DateTime.now());

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      titleVi: json['title_vi'],
      description: json['description'],
      descriptionVi: json['description_vi'],
      poster: json['poster'],
      backdrop: json['backdrop'],
      trailer: json['trailer'],
      releaseDate: DateTime.parse(json['release_date']),
      duration: int.parse(json['duration'].toString()),
      genres: json['genres'] != null
          ? (json['genres'] as List)
              .map((genreJson) => Genre.fromJson(genreJson))
              .toList()
          : [],
      rating: json['rating'] != null
          ? double.tryParse(json['rating'].toString())
          : null,
      country: json['country'] ?? '',
      language: json['language'] ?? '',
      director: json['director'],
      cast: json['cast'] != null ? List<String>.from(json['cast']) : null,
      slug: json['slug'],
      featured: json['featured'] == true || json['featured'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_vi': titleVi,
      'description': description,
      'description_vi': descriptionVi,
      'poster': poster,
      'backdrop': backdrop,
      'trailer': trailer,
      'release_date': releaseDate.toIso8601String(),
      'duration': duration,
      'genre': genres,
      'rating': rating,
      'country': country,
      'language': language,
      'director': director,
      'cast': cast,
      'slug': slug,
      'featured': featured,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class MoviesResponse {
  final List<Movie> movies;
  final int currentPage;
  final int lastPage;
  final int total;

  MoviesResponse({
    required this.movies,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory MoviesResponse.fromJson(Map<String, dynamic> json) {
    // API trả về cấu trúc: data.data = danh sách phim
    var moviesList = json['data'] as List;
    List<Movie> movies = moviesList.map((i) => Movie.fromJson(i)).toList();

    return MoviesResponse(
      movies: movies,
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      total: json['total'],
    );
  }
}
