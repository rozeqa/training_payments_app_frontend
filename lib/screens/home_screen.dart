import 'package:flutter/material.dart';
import 'people_screen.dart';
import 'calendar_screen.dart';
import 'payments_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  final pages = const [
    PeopleScreen(),
    CalendarScreen(),
    PaymentsScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organizacja treningów agility')),
      body: pages[index],
      
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),

        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: Colors.transparent,

        destinations: const [
          NavigationDestination(icon: Icon(Icons.people), label: 'Osoby'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Kalendarz'),
          NavigationDestination(icon: Icon(Icons.payments), label: 'Wpłaty'),
          NavigationDestination(icon: Icon(Icons.insert_chart), label: 'Raporty'),
        ],
      ),
    );
  }
}
