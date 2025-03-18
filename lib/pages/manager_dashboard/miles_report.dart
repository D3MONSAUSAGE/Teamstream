import 'package:flutter/material.dart';
import 'package:teamstream/services/pocketbase/miles_service.dart';

class MilesReportPage extends StatefulWidget {
  const MilesReportPage({super.key});

  @override
  _MilesReportPageState createState() => _MilesReportPageState();
}

class _MilesReportPageState extends State<MilesReportPage> {
  List<Map<String, dynamic>> mileageRecords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMilesData();
  }

  Future<void> _fetchMilesData() async {
    try {
      final data = await MilesService.fetchMilesData();
      setState(() {
        mileageRecords = data;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching miles data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Miles Report")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mileageRecords.length,
              itemBuilder: (context, index) {
                var record = mileageRecords[index];
                return Card(
                  child: ListTile(
                    title: Text("Trip ID: ${record["trip_id"]}"),
                    subtitle: Text(
                        "Miles: ${record["miles"]} | Cost: \$${record["cost"]}"),
                  ),
                );
              },
            ),
    );
  }
}
