import 'package:flutter/material.dart';

class VendorManagementPage extends StatelessWidget {
  const VendorManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vendor Management")),
      body: const Center(
        child: Text("Vendor Database & Management Coming Soon!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
