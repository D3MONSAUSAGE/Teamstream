import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final List<String> statusOptions = ["All", "Pending", "Approved", "Rejected"];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => isLoading = true);
    try {
      List<Map<String, dynamic>> fetchedInvoices =
          await InvoiceService.fetchInvoices();
      if (mounted) {
        setState(() {
          invoices = fetchedInvoices;
          isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Error loading invoices: $e', isError: true);
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _uploadInvoice() {
    TextEditingController vendorController = TextEditingController();
    TextEditingController amountController = TextEditingController();
    TextEditingController notesController = TextEditingController();
    DateTime? selectedDate = DateTime.now();
    PlatformFile? selectedFile;

    Future<void> _pickFile() async {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'png'],
        );
        if (result != null) {
          if (result.files.single.size > 5 * 1024 * 1024) {
            _showSnackBar('File size must be under 5MB!', isError: true);
            return;
          }
          setState(() => selectedFile = result.files.first);
        }
      } catch (e) {
        _showSnackBar('Error picking file: $e', isError: true);
      }
    }

    Future<void> _pickDate() async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate!,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        builder: (context, child) => Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
          ),
          child: child!,
        ),
      );
      if (pickedDate != null && mounted) {
        setState(() => selectedDate = pickedDate);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          title: Text(
            'Upload Invoice',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: vendorController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'Vendor',
                    labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                    prefixIcon:
                        const Icon(Icons.business, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedDate == null
                                ? 'Select Invoice Date'
                                : DateFormat('yyyy-MM-dd')
                                    .format(selectedDate!),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: selectedDate == null
                                  ? Colors.grey[700]
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedFile == null
                                ? 'Select Invoice File (PDF, JPG, PNG)'
                                : 'File: ${selectedFile!.name}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: selectedFile == null
                                  ? Colors.grey[700]
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                    prefixIcon: const Icon(Icons.attach_money,
                        color: Colors.blueAccent),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                    prefixIcon:
                        const Icon(Icons.note, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (vendorController.text.isEmpty ||
                    selectedDate == null ||
                    selectedFile == null ||
                    amountController.text.isEmpty) {
                  _showSnackBar('Please fill in all required fields.',
                      isError: true);
                  return;
                }

                double? amount = double.tryParse(amountController.text);
                if (amount == null) {
                  _showSnackBar('Invalid amount entered.', isError: true);
                  return;
                }

                try {
                  await InvoiceService.uploadInvoice(
                    vendor: vendorController.text.trim(),
                    date: selectedDate!,
                    amount: amount,
                    notes: notesController.text.trim(),
                    file: selectedFile!,
                  );
                  _showSnackBar('Invoice uploaded successfully!',
                      isSuccess: true);
                  _loadInvoices();
                  Navigator.pop(context);
                } catch (e) {
                  _showSnackBar('Error uploading invoice: $e', isError: true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Upload',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteInvoice(String invoiceId) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        title: Text(
          'Confirm Deletion',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.blue[900],
          ),
        ),
        content: Text(
          'Are you sure you want to delete this invoice?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      bool success = await InvoiceService.deleteInvoice(invoiceId);
      if (success) {
        _showSnackBar('Invoice deleted successfully!', isSuccess: true);
        _loadInvoices();
      } else {
        _showSnackBar('Failed to delete invoice.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error deleting invoice: $e', isError: true);
    }
  }

  Future<void> _changeInvoiceStatus(String invoiceId, String status) async {
    try {
      await InvoiceService.updateInvoiceStatus(invoiceId, status);
      _showSnackBar('Invoice status updated to $status!', isSuccess: true);
      _loadInvoices();
    } catch (e) {
      _showSnackBar('Error updating invoice status: $e', isError: true);
    }
  }

  void _showFilterDialog() {
    DateTime? tempStartDate = filterStartDate;
    DateTime? tempEndDate = filterEndDate;
    String tempStatus = selectedStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          title: Text(
            'Filter Invoices',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[900],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: tempStartDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Colors.blueAccent),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null)
                      setDialogState(() => tempStartDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tempStartDate == null
                                ? 'Start Date'
                                : DateFormat('yyyy-MM-dd')
                                    .format(tempStartDate!),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: tempStartDate == null
                                  ? Colors.grey[700]
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: tempEndDate ?? DateTime.now(),
                      firstDate: tempStartDate ?? DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Colors.blueAccent),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null)
                      setDialogState(() => tempEndDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tempEndDate == null
                                ? 'End Date'
                                : DateFormat('yyyy-MM-dd').format(tempEndDate!),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: tempEndDate == null
                                  ? Colors.grey[700]
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tempStatus,
                  items: statusOptions
                      .map((status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(status, style: GoogleFonts.poppins()),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => tempStatus = value!),
                  style: GoogleFonts.poppins(),
                  decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                    prefixIcon:
                        const Icon(Icons.filter_list, color: Colors.blueAccent),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  filterStartDate = tempStartDate;
                  filterEndDate = tempEndDate;
                  selectedStatus = tempStatus;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Apply',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor:
            isSuccess ? Colors.green : (isError ? Colors.red : null),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> _filteredInvoices() {
    return invoices.where((invoice) {
      bool matchesSearch = invoice["vendor"]
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      bool matchesDate = true;
      if (filterStartDate != null) {
        matchesDate = DateTime.parse(invoice["date"]).isAfter(filterStartDate!);
      }
      if (filterEndDate != null) {
        matchesDate = matchesDate &&
            DateTime.parse(invoice["date"])
                .isBefore(filterEndDate!.add(const Duration(days: 1)));
      }
      bool matchesStatus =
          selectedStatus == "All" || invoice["status"] == selectedStatus;
      return matchesSearch && matchesDate && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    var filteredInvoices = _filteredInvoices();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Invoice List',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 28),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
            onPressed: _loadInvoices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    style: GoogleFonts.poppins(),
                    decoration: InputDecoration(
                      hintText: 'Search by vendor...',
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.blueAccent),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ),
                Expanded(
                  child: filteredInvoices.isEmpty
                      ? Center(
                          child: Text(
                            'No invoices found.',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          children: [
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Invoice List',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: filteredInvoices.length,
                                      itemBuilder: (context, index) {
                                        var invoice = filteredInvoices[index];
                                        return Card(
                                          elevation: 1,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: ListTile(
                                            leading: const Icon(Icons.receipt,
                                                color: Colors.blueAccent,
                                                size: 24),
                                            title: Text(
                                              invoice["vendor"],
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(invoice["date"]))}',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 12),
                                                ),
                                                Text(
                                                  'Amount: \$${(invoice["amount"] as num? ?? 0).toStringAsFixed(2)}',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 12),
                                                ),
                                                Text(
                                                  'Status: ${invoice["status"]}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: invoice["status"] ==
                                                            "Approved"
                                                        ? Colors.green
                                                        : invoice["status"] ==
                                                                "Pending"
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
                                                PopupMenuItem(
                                                  value: "Delete",
                                                  child: Text(
                                                    'Delete',
                                                    style: GoogleFonts.poppins(
                                                        color: Colors.red),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: "Approved",
                                                  child: Text(
                                                    'Mark as Approved',
                                                    style: GoogleFonts.poppins(
                                                        color: Colors.green),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: "Rejected",
                                                  child: Text(
                                                    'Mark as Rejected',
                                                    style: GoogleFonts.poppins(
                                                        color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadInvoice,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.upload, color: Colors.white, size: 28),
      ),
    );
  }
}
