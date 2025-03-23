import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:teamstream/utils/constants.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/services/pocketbase/role_service.dart';
import 'package:teamstream/pages/manager_dashboard/inventory_report.dart';
import 'package:teamstream/pages/manager_dashboard/checklists_report.dart';
import 'package:teamstream/pages/manager_dashboard/requests_report.dart';
import 'package:teamstream/pages/manager_dashboard/miles_report.dart';
import 'package:teamstream/pages/manager_dashboard/daily_sales_report.dart';
import 'package:teamstream/pages/notifications/notifications.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:teamstream/pages/manage_schedules/manage_schedules_page.dart';

class ManagerDashboardPage extends StatefulWidget {
  const ManagerDashboardPage({super.key});

  @override
  State<ManagerDashboardPage> createState() => _ManagerDashboardPageState();
}

class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  void _checkAdminStatus() {
    setState(() {
      _isAdmin = RoleService.isAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Manager Dashboard",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, size: 28),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text("Filter coming soon!", style: GoogleFonts.poppins()),
                  backgroundColor: Colors.blueAccent,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
            child: Text(
              "Overview",
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
          Expanded(
            child: AnimationLimiter(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(12),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: AnimationConfiguration.toStaggeredList(
                  duration: const Duration(milliseconds: 375),
                  childAnimationBuilder: (widget) => SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(child: widget),
                  ),
                  children: [
                    _buildDashboardCard(
                      context,
                      "Inventory Report",
                      const InventoryReportPage(),
                      Icons.inventory_outlined,
                    ),
                    _buildDashboardCard(
                      context,
                      "Checklists Report",
                      const ChecklistsReportPage(),
                      Icons.checklist_outlined,
                    ),
                    _buildDashboardCard(
                      context,
                      "Requests Report",
                      const RequestsReportPage(),
                      Icons.request_page_outlined,
                    ),
                    _buildDashboardCard(
                      context,
                      "Miles Report",
                      const MilesReportPage(),
                      Icons.directions_car_outlined,
                    ),
                    _buildDashboardCard(
                      context,
                      "Daily Sales Report",
                      const DailySalesReportsPage(),
                      Icons.attach_money_outlined,
                    ),
                    _buildDashboardCard(
                      context,
                      "Notifications",
                      const NotificationsPage(),
                      Icons.notifications_outlined,
                      badgeCount: 3,
                    ),
                    _buildDashboardCard(
                      context,
                      "Manage Schedules",
                      const ManageSchedulesPage(),
                      Icons.schedule_outlined,
                    ),
                    if (_isAdmin)
                      _buildDashboardCard(
                        context,
                        "Timecard",
                        null,
                        Icons.access_time,
                        onTap: () {
                          Navigator.pushNamed(context, '/timecard');
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Data refreshed", style: GoogleFonts.poppins()),
              backgroundColor: Colors.blueAccent,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    Widget? page,
    IconData icon, {
    int? badgeCount,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ??
          () {
            if (page != null) {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => page));
            }
          },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 40,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "$badgeCount",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
