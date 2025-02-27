import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teamstream/services/pocketbase/invoice_service.dart';
import 'package:file_picker/file_picker.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  InvoiceListPageState createState() => InvoiceListPageState();
}

class InvoiceListPageState extends State<InvoiceListPage> {
  List<Map<String, dynamic>> invoices = [];
  bool isLoading = true;
  String searchQuery = "";
  DateTime? filterStartDate;
  DateTime? filterEndDate;
  String selectedStatus = "All";

  @override
  void initState() {
    super.initState();
    loadInvoices();
  }

  /// 🔹 Fetch invoices from PocketBase
  void loadInvoices() async {
    List<Map<String, dynamic>> fetchedInvoices =
        await InvoiceService.fetchInvoices();
    setState(() {
      invoices = fetchedInvoices;
      isLoading = false;
    });
  }

  /// 🔹 Upload New Invoice
  void _uploadInvoice() async {
    TextEditingController vendorController = TextEditingController();
    TextEditingController amountController = TextEditingController();
    TextEditingController notesController = TextEditingController();
    DateTime? selectedDate;
    PlatformFile? selectedFile;

    void _pickFile() async {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
      );
      if (result != null) {
        setState(() {
          selectedFile = result.files.first;
        });
      }
    }

    void _pickDate() async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (pickedDate != null) {
        setState(() {
          selectedDate = pickedDate;
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Upload Invoice"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: vendorController,
                  decoration: const InputDecoration(labelText: "Vendor"),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: Text(selectedDate == null
                      ? "Select Invoice Date"
                      : "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}"),
                  leading: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                ListTile(
                  title: Text(selectedFile == null
                      ? "Select Invoice File"
                      : "File: ${selectedFile!.name}"),
                  leading: const Icon(Icons.attach_file),
                  onTap: _pickFile,
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount"),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: "Notes"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (vendorController.text.isEmpty ||
                    selectedDate == null ||
                    selectedFile == null ||
                    amountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please fill in all required fields.")),
                  );
                  return;
                }

                double? amount = double.tryParse(amountController.text);
                if (amount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid amount entered.")),
                  );
                  return;
                }

                await InvoiceService.uploadInvoice(
                  vendor: vendorController.text,
                  date: selectedDate!,
                  amount: amount,
                  notes: notesController.text,
                  file: selectedFile!,
                );

                loadInvoices();
                Navigator.pop(context);
              },
              child: const Text("Upload"),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Delete Invoice
  void _deleteInvoice(String invoiceId) async {
    bool success = await InvoiceService.deleteInvoice(invoiceId);
    if (success) {
      loadInvoices();
    }
  }

  /// 🔹 Change Invoice Status
  void _changeInvoiceStatus(String invoiceId, String status) async {
    await InvoiceService.updateInvoiceStatus(invoiceId, status);
    loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invoices")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: invoices.isEmpty
                      ? const Center(child: Text("No invoices found."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: invoices.length,
                          itemBuilder: (context, index) {
                            var invoice = invoices[index];

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: const Icon(Icons.receipt,
                                    color: Colors.blue),
                                title: Text(invoice["vendor"],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(invoice["date"]))}"),
                                    Text("Amount: \$${invoice["amount"]}"),
                                    Text(
                                      "Status: ${invoice["status"]}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: invoice["status"] == "Approved"
                                            ? Colors.green
                                            : invoice["status"] == "Pending"
                                                ? Colors.orange
                                                : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == "Delete") {
                                      _deleteInvoice(invoice["id"]);
                                    } else {
                                      _changeInvoiceStatus(
                                          invoice["id"], value);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                        value: "Delete", child: Text("Delete")),
                                    const PopupMenuItem(
                                        value: "Approved",
                                        child: Text("Mark as Approved")),
                                    const PopupMenuItem(
                                        value: "Rejected",
                                        child: Text("Mark as Rejected")),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadInvoice,
        child: const Icon(Icons.upload),
      ),
    );
  }
}
