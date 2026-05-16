import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../pages_user/user_functions_page.dart';
import '../pages_user/user_transactions_page.dart';
import '../pages_user/user_activities_page.dart';
import '../pages_user/user_profile_page.dart';
import '../pages_user/mobile_payment_scanner_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _listenForScannerTriggers();
  }

  void _listenForScannerTriggers() {
    FirebaseFirestore.instance
        .collection('scanner_triggers')
        .doc('SP001')
        .snapshots()
        .listen((doc) {
          if (doc.exists && doc.data()?['trigger'] == true) {
            final data = doc.data()!;

            // Navigate to payment scanner
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MobilePaymentScannerPage(triggerData: data),
              ),
            );
          }
        });
  }

  final List<Widget> _pages = [
    const UserFunctionsPage(),
    const UserTransactionsPage(),
    const UserActivitiesPage(),
    const UserProfilePage(),
  ];

  final List<String> _titles = [
    'Functions',
    'Transactions',
    'Activities',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(_titles[_currentIndex]),
          elevation: 0,
        ),
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _currentIndex, children: _pages),
        ),
        extendBody: true,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.deepPurple,
          onTap: (idx) => setState(() => _currentIndex = idx),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              label: 'Functions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event),
              label: 'Activities',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

/// Simple wrapper to keep state alive for children inside the Stack.
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({required this.child, super.key});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
