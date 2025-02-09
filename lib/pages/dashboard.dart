import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teamstream/widgets/menu_drawer.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const MenuDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Back!",
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 5),
            const Text(
              "Here’s a quick overview of your progress.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // 🔵 Training Completion Pie Chart
            _buildTrainingPieChart(),

            const SizedBox(height: 20),

            // 💰 Financial Overview Bar Chart
            _buildFinancialBarChart(),

            const SizedBox(height: 20),

            // 📈 Progress Line Chart
            _buildProgressLineChart(),
          ],
        ),
      ),
    );
  }

  /// 🔵 Training Completion Pie Chart
  Widget _buildTrainingPieChart() {
    return _buildCard(
      title: "Training Completion",
      child: PieChart(
        PieChartData(
          sectionsSpace: 5,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              value: 60,
              color: Colors.blueAccent,
              title: "60%",
              radius: 50,
              titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            PieChartSectionData(
              value: 40,
              color: Colors.grey,
              title: "40%",
              radius: 50,
              titleStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// 💰 Financial Overview Bar Chart
  Widget _buildFinancialBarChart() {
    return _buildCard(
      title: "Monthly Revenue",
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          barGroups: [
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(toY: 8000, color: Colors.blueAccent, width: 16),
            ]),
            BarChartGroupData(x: 2, barRods: [
              BarChartRodData(toY: 10000, color: Colors.green, width: 16),
            ]),
            BarChartGroupData(x: 3, barRods: [
              BarChartRodData(toY: 12000, color: Colors.orange, width: 16),
            ]),
            BarChartGroupData(x: 4, barRods: [
              BarChartRodData(toY: 15000, color: Colors.redAccent, width: 16),
            ]),
          ],
        ),
      ),
    );
  }

  /// 📈 Training Progress Line Chart
  Widget _buildProgressLineChart() {
    return _buildCard(
      title: "Training Progress Over Time",
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(1, 10),
                const FlSpot(2, 30),
                const FlSpot(3, 50),
                const FlSpot(4, 70),
                const FlSpot(5, 90),
              ],
              isCurved: true,
              barWidth: 4,
              color: Colors.blueAccent,
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎨 General Card Styling
  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }
}
