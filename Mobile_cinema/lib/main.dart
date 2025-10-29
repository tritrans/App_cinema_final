import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/providers.dart';
import 'utils/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart'; // Import LoginScreen
import 'screens/main_screen.dart'; // Import MainScreen

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication Provider
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Movie Provider
        ChangeNotifierProvider(create: (_) => MovieProvider()),

        // Schedule Provider
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),

        // Theater Provider
        ChangeNotifierProvider(create: (_) => TheaterProvider()),

        // Booking Provider
        ChangeNotifierProvider(create: (_) => BookingProvider()),

        // Ticket Provider
        ChangeNotifierProvider(create: (_) => TicketProvider()),

        // Favorite Provider
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),

        // Theme Provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Review Provider
        ChangeNotifierProvider(create: (_) => ReviewProvider()),

        // Comment Provider
        ChangeNotifierProvider(create: (_) => CommentProvider()),

        // Cast Provider
        ChangeNotifierProvider(create: (_) => CastProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey, // Assign the global key here
            title: 'Cinema Booking App',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch:
                  Colors.red, // Changed to red as per user's preference
              visualDensity: VisualDensity.adaptivePlatformDensity,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.black),
                titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            home: const SplashScreen(),
            // You can add routes here for navigation
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(), // Add login route
              '/main': (context) => const MainScreen(), // Add main route
              // Add other routes as needed
            },
          );
        },
      ),
    );
  }
}

// Example of how to use the providers in a screen
class ExampleUsageScreen extends StatefulWidget {
  const ExampleUsageScreen({super.key});

  @override
  State<ExampleUsageScreen> createState() => _ExampleUsageScreenState();
}

class _ExampleUsageScreenState extends State<ExampleUsageScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize providers when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final movieProvider = Provider.of<MovieProvider>(context, listen: false);
    final theaterProvider =
        Provider.of<TheaterProvider>(context, listen: false);

    // Initialize authentication
    await authProvider.initializeAuth();

    // Load initial data
    await Future.wait([
      movieProvider.getFeaturedMovies(),
      movieProvider.getMovies(),
      theaterProvider.getTheaters(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cinema App'),
        actions: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isAuthenticated) {
                return PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await authProvider.logout();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          const Icon(Icons.person),
                          const SizedBox(width: 8),
                          Text(authProvider.currentUser?.name ?? 'Profile'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Đăng xuất'),
                        ],
                      ),
                    ),
                  ],
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(
                        authProvider.currentUser?.avatarUrl ??
                            'https://via.placeholder.com/150'),
                  ),
                );
              } else {
                return TextButton(
                  onPressed: () {
                    // Navigate to login screen
                  },
                  child: const Text('Đăng nhập'),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Movies Section
            const Text(
              'Phim Nổi Bật',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<MovieProvider>(
              builder: (context, movieProvider, child) {
                if (movieProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (movieProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      children: [
                        Text('Lỗi: ${movieProvider.errorMessage}'),
                        ElevatedButton(
                          onPressed: () => movieProvider.getFeaturedMovies(),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: movieProvider.featuredMovies.length,
                    itemBuilder: (context, index) {
                      final movie = movieProvider.featuredMovies[index];
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  movie.poster,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.movie),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              movie.title,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (movie.rating != null)
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 12, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    movie.rating!.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Theaters Section
            const Text(
              'Rạp Chiếu Phim',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<TheaterProvider>(
              builder: (context, theaterProvider, child) {
                if (theaterProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (theaterProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      children: [
                        Text('Lỗi: ${theaterProvider.errorMessage}'),
                        ElevatedButton(
                          onPressed: () => theaterProvider.getTheaters(),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: theaterProvider.theaters.length,
                  itemBuilder: (context, index) {
                    final theater = theaterProvider.theaters[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.local_movies),
                        ),
                        title: Text(theater.name),
                        subtitle: Text(theater.fullAddress),
                        trailing: Text('${theater.totalSeats} ghế'),
                        onTap: () {
                          // Navigate to theater details
                          theaterProvider.setCurrentTheater(theater);
                        },
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // User Bookings Section (if authenticated)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (!authProvider.isAuthenticated) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vé Của Tôi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<BookingProvider>(
                      builder: (context, bookingProvider, child) {
                        if (bookingProvider.isLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (bookingProvider.errorMessage != null) {
                          return Center(
                            child: Column(
                              children: [
                                Text('Lỗi: ${bookingProvider.errorMessage}'),
                                ElevatedButton(
                                  onPressed: () =>
                                      bookingProvider.getUserBookings(
                                          authProvider.currentUser!.id),
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          );
                        }

                        final upcomingBookings =
                            bookingProvider.upcomingBookings;

                        if (upcomingBookings.isEmpty) {
                          return const Center(
                            child: Text('Bạn chưa có vé nào'),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: upcomingBookings.length,
                          itemBuilder: (context, index) {
                            final booking = upcomingBookings[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    booking.moviePoster,
                                    width: 50,
                                    height: 75,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 50,
                                        height: 75,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.movie),
                                      );
                                    },
                                  ),
                                ),
                                title: Text(booking.movieTitle),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(booking.theaterName),
                                    Text(
                                        '${booking.showDateString} - ${booking.showTimeString}'),
                                    Text('Ghế: ${booking.seatNumbers}'),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${booking.totalPrice.toStringAsFixed(0)} VND',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(
                                                booking.statusColor
                                                    .substring(1),
                                                radix: 16) +
                                            0xFF000000),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        booking.statusText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Navigate to booking details
                                  bookingProvider
                                      .getBookingDetails(booking.bookingId);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
