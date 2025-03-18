import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamstream/widgets/menu_drawer.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Sample notification data (replace with real data source in production)
  List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'title': 'New Inventory Report',
      'message': 'Inventory report for March is ready.',
      'timestamp': '2025-03-16 10:30 AM',
      'isRead': false,
      'icon': Icons.inventory_outlined,
    },
    {
      'id': '2',
      'title': 'Checklist Reminder',
      'message': 'Daily checklist due in 1 hour.',
      'timestamp': '2025-03-16 09:15 AM',
      'isRead': true,
      'icon': Icons.checklist_outlined,
    },
    {
      'id': '3',
      'title': 'Request Approved',
      'message': 'Your leave request has been approved.',
      'timestamp': '2025-03-15 03:45 PM',
      'isRead': false,
      'icon': Icons.request_page_outlined,
    },
  ];

  void _markAsRead(String id) {
    setState(() {
      final index = notifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        notifications[index]['isRead'] = true;
      }
    });
    _showSnackBar('Notification marked as read');
  }

  void _clearAll() {
    setState(() {
      notifications.clear();
    });
    _showSnackBar('All notifications cleared', isSuccess: true);
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isSuccess
            ? Colors.green
            : (isError
                ? Colors.red
                : Colors.blueAccent), // Match ManagerDashboardPage
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Match ManagerDashboardPage
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white, // Match ManagerDashboardPage
            fontSize: 20, // Match ManagerDashboardPage
          ),
        ),
        elevation: 0, // Match ManagerDashboardPage
        backgroundColor: Colors.blueAccent, // Match ManagerDashboardPage
        iconTheme: const IconThemeData(
            color: Colors.white), // Match ManagerDashboardPage
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, size: 28), // Clear all action
            onPressed: notifications.isEmpty
                ? null
                : () {
                    _clearAll();
                  },
            tooltip: 'Clear All',
          ),
        ],
      ),
      drawer: const MenuDrawer(), // Match ManagerDashboardPage
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
            12, 24, 12, 16), // Match ManagerDashboardPage
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Notifications',
              style: GoogleFonts.poppins(
                fontSize: 26, // Match ManagerDashboardPage
                fontWeight: FontWeight.bold, // Match ManagerDashboardPage
                color: Colors.blue[900], // Match ManagerDashboardPage
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications yet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                  12), // Match ManagerDashboardPage
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(
                                      0.2), // Match ManagerDashboardPage
                                  blurRadius: 2, // Match ManagerDashboardPage
                                  offset: const Offset(0, 1),
                                ),
                              ],
                              border: Border.all(
                                color: notification['isRead']
                                    ? Colors.transparent
                                    : Colors.blueAccent
                                        .withOpacity(0.5), // Highlight unread
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors
                                    .blueAccent, // Match ManagerDashboardPage
                                child: Icon(
                                  notification['icon'],
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                notification['title'],
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight
                                      .w500, // Match ManagerDashboardPage
                                  color: Colors
                                      .blue[900], // Match ManagerDashboardPage
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification['message'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['timestamp'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  notification['isRead']
                                      ? Icons.check_circle_outline
                                      : Icons.mark_email_unread,
                                  color: notification['isRead']
                                      ? Colors.grey[600]
                                      : Colors.blueAccent,
                                ),
                                onPressed: notification['isRead']
                                    ? null
                                    : () => _markAsRead(notification['id']),
                                tooltip: notification['isRead']
                                    ? 'Read'
                                    : 'Mark as Read',
                              ),
                              onTap: () {
                                // Optional: Navigate to related page or show details
                                _showSnackBar(
                                    'Tapped: ${notification['title']}');
                                if (!notification['isRead']) {
                                  _markAsRead(notification['id']);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSnackBar('Notifications refreshed');
          // Add refresh logic here if connected to a data source
        },
        backgroundColor: Colors.blueAccent, // Match ManagerDashboardPage
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      home: const NotificationsPage(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100], // Match ManagerDashboardPage
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
    ),
  );
}
