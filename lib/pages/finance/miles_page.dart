import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';
import 'package:teamstream/services/pocketbase/miles_service.dart';

class MilesPage extends StatefulWidget {
  const MilesPage({super.key});

  @override
  MilesPageState createState() => MilesPageState();
}

class MilesPageState extends State<MilesPage> {
  final TextEditingController milesController = TextEditingController();
  final TextEditingController commentsController = TextEditingController();
  String selectedReason = "Work Assignment";
  Uint8List? selectedImage;
  String payRatePerMile = "0.50"; // Default pay rate (fetch dynamically)
  bool isSubmitting = false;

  final List<String> travelReasons = [
    "Work Assignment",
    "Client Visit",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    // Fetch pay rate dynamically (example)
    fetchPayRate();
  }

  Future<void> fetchPayRate() async {
    // Simulate fetching pay rate from an API or backend
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    setState(() {
      payRatePerMile = "0.50"; // Replace with actual API call
    });
  }

  void pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          selectedImage = result.files.first.bytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image: ${e.toString()}")),
      );
    }
  }

  double calculateTotalPay() {
    double miles = double.tryParse(milesController.text) ?? 0;
    double rate = double.tryParse(payRatePerMile) ?? 0;
    return miles * rate;
  }

  void submitMileage() async {
    double miles = double.tryParse(milesController.text) ?? 0;
    if (miles <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid number of miles.")),
      );
      return;
    }

    if (selectedReason.isEmpty || selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("Please fill all required fields and upload an image.")),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    String? userId = AuthService.getLoggedInUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in!")),
      );
      return;
    }

    bool success = await MilesService.submitMileage(
      employeeId: userId,
      miles: milesController.text.trim(),
      comments: commentsController.text.trim(),
      reason: selectedReason,
      image: selectedImage!,
      payPerMile: payRatePerMile,
    );

    setState(() {
      isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mileage submitted successfully!")),
      );
      Navigator.pop(context); // Go back to the previous page
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error submitting mileage. Try again!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit Mileage"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pay Rate Display
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.green),
                      const SizedBox(width: 10),
                      Text(
                        "Pay Rate Per Mile: \$$payRatePerMile",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Miles Input
              TextField(
                controller: milesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Miles Traveled",
                  prefixIcon: const Icon(Icons.directions_car),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: (value) {
                  setState(() {}); // Update total pay in real-time
                },
              ),
              const SizedBox(height: 20),

              // Total Pay Display
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.money, color: Colors.blue),
                      const SizedBox(width: 10),
                      Text(
                        "Total Pay: \$${calculateTotalPay().toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Reason Dropdown
              DropdownButtonFormField<String>(
                value: selectedReason,
                items: travelReasons
                    .map((reason) => DropdownMenuItem(
                          value: reason,
                          child: Text(reason),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReason = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Reason for Travel",
                  prefixIcon: const Icon(Icons.work),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 20),

              // Comments Input
              TextField(
                controller: commentsController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Additional Comments",
                  prefixIcon: const Icon(Icons.comment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 20),

              // Image Upload
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (selectedImage != null)
                        Image.memory(
                          selectedImage!,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(selectedImage == null
                            ? "Upload Receipt/Proof"
                            : "Change Image"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitMileage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Submit Mileage",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
