import 'package:flutter/material.dart';
import 'package:teamstream/services/pocketbase/requests_service.dart';

class RequestsReportPage extends StatefulWidget {
  const RequestsReportPage({super.key});

  @override
  _RequestsReportPageState createState() => _RequestsReportPageState();
}

class _RequestsReportPageState extends State<RequestsReportPage> {
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final data = await RequestsService.fetchRequests();
      setState(() {
        requests = data;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching requests: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Requests Report")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                var request = requests[index];
                return Card(
                  child: ListTile(
                    title: Text(request["type"] ?? "Unknown Request"),
                    subtitle: Text(
                        "Status: ${request["approved"] ? "Approved" : "Pending"}"),
                    trailing: request["approved"]
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.hourglass_empty,
                            color: Colors.orange),
                  ),
                );
              },
            ),
    );
  }
}
