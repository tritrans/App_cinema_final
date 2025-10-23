// DEPRECATED: This file is no longer used. Use ApiService instead.
// All content has been commented out to avoid conflicts.

/*
import 'api_client.dart';

class CinemaApiService {
  // ... all content commented out
}
*/

// Placeholder class to avoid import errors
class CinemaApiService {
  Future<List<dynamic>> getMovies(
      {String? genre, bool? featured, int page = 1, int perPage = 12}) async {
    return [];
  }

  Future<List<dynamic>> getFavorites() async {
    return [];
  }

  Future<bool> addFavorite({
    required String movieId,
    required String title,
    required String posterUrl,
  }) async {
    return false;
  }

  Future<bool> removeFavorite(String movieId) async {
    return false;
  }
}

// Global instance for backward compatibility
final cinemaApi = CinemaApiService();
