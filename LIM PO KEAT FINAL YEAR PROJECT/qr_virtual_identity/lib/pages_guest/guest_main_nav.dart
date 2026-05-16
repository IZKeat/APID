// lib/pages_guest/guest_main_nav.dart
import 'package:flutter/material.dart';
import 'guest_events_page.dart';
import 'guest_my_tickets_page.dart';
import 'guest_profile_page.dart';

/// 🧭 Guest Main Navigation
/// Bottom navigation controller for Guest Mode
/// Switches between: Events Hub, My Tickets, and Profile
class GuestMainNav extends StatefulWidget {
  const GuestMainNav({super.key});

  @override
  State<GuestMainNav> createState() => _GuestMainNavState();
}

class _GuestMainNavState extends State<GuestMainNav> {
  int _currentIndex = 0;

  void _switchToMyTickets() {
    setState(() {
      _currentIndex = 1; // Switch to My Tickets tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const GuestEventsPage(), // Index 0: Event Hub
          const GuestMyTicketsPage(), // Index 1: My Tickets
          GuestProfilePage(
            onNavigateToTickets: _switchToMyTickets, // Index 2: Profile
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFFFFA000), // Amber
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Home',
            tooltip: 'Browse Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_num_outlined),
            label: 'My Tickets',
            tooltip: 'View Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
            tooltip: 'My Profile',
          ),
        ],
      ),
    );
  }
}
