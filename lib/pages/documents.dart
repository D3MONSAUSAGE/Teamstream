import 'package:flutter/material.dart';
import 'package:teamstream/widgets/menu_drawer.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Company Documents")),
      drawer: const MenuDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Company Policies & Documents",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildDocumentCard(
                      context,
                      "Order Pick Up Policy",
                      "Guidelines for customers and employees on how to handle order pick-ups.",
                      Icons.assignment),
                  _buildDocumentCard(
                      context,
                      "Uniform Policy",
                      "Rules regarding employee uniforms, grooming, and professional appearance.",
                      Icons.work),
                  _buildDocumentCard(
                      context,
                      "Uniform Request Policy",
                      "Process for requesting new uniforms or replacement items.",
                      Icons.shopping_cart),
                  _buildDocumentCard(
                      context,
                      "POS Card Policy",
                      "Proper use and security guidelines for handling POS cards.",
                      Icons.credit_card),
                  _buildDocumentCard(
                      context,
                      "Return Policy",
                      "Instructions for processing customer returns and refunds.",
                      Icons.autorenew),
                  _buildDocumentCard(
                      context,
                      "Raise Policy",
                      "Details on performance evaluations and raise eligibility.",
                      Icons.trending_up),
                  _buildDocumentCard(
                      context,
                      "Sexual Harassment Policy",
                      "Zero tolerance policy for harassment, reporting procedures, and consequences.",
                      Icons.security),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(
      BuildContext context, String title, String description, IconData icon) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.open_in_new, color: Colors.blue),
        onTap: () {
          // ✅ Use the context inside the function properly
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title will be available soon.")),
          );
        },
      ),
    );
  }
}
