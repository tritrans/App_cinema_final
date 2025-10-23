import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'ticket_screen.dart';
import 'profile_screen.dart';
import '../providers/ticket_provider.dart';
import '../providers/favorite_provider.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TicketScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadDataForCurrentUser();
  }

  Future<void> _loadDataForCurrentUser() async {
    // Defer provider API calls until after the first frame so providers can
    // safely call notifyListeners without triggering "setState during build"
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('MainScreen: Loading tickets and favorites from API...');
      try {
        await context.read<FavoriteProvider>().getFavorites();
      } catch (e) {
        // swallow errors - providers handle their own error state
      }

      try {
        // Load tickets from API (user id is obtained internally by provider)
        await context.read<TicketProvider>().loadTicketsFromAPI(1);
      } catch (e) {
        // ignore
      }

      if (!mounted) return;
      setState(() {});
    });
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Vé của tôi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        onTap: _onItemTapped,
      ),
    );
  }
}
