import 'package:flutter/material.dart';
import 'package:teamstream/widgets/menu_drawer.dart';
import 'package:teamstream/services/pocketbase_service.dart';

class HumanResourcesPage extends StatefulWidget {
  const HumanResourcesPage({super.key});

  @override
  HumanResourcesPageState createState() => HumanResourcesPageState();
}

class HumanResourcesPageState extends State<HumanResourcesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Human Resources",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.greenAccent,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Employees"),
            Tab(text: "Onboarding"),
            Tab(text: "Requests"),
            Tab(text: "Suggestions"),
            Tab(text: "Documents"),
          ],
        ),
      ),
      drawer: const MenuDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: [
          EmployeesTab(),
          OnboardingTab(),
          const RequestsTab(),
          SuggestionsTab(),
          DocumentsTab(),
        ],
      ),
    );
  }
}

// 📌 Employees Tab (Search & List Employees)
class EmployeesTab extends StatefulWidget {
  const EmployeesTab({super.key});

  @override
  EmployeesTabState createState() => EmployeesTabState();
}

class EmployeesTabState extends State<EmployeesTab> {
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> filteredEmployees = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  void fetchEmployees() async {
    try {
      List<Map<String, dynamic>> fetchedEmployees =
          await PocketBaseService.fetchEmployees();
      setState(() {
        employees = fetchedEmployees;
        filteredEmployees = fetchedEmployees;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching employees: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterEmployees(String query) {
    setState(() {
      filteredEmployees = employees
          .where((employee) =>
              employee['name'].toLowerCase().contains(query.toLowerCase()) ||
              employee['role'].toLowerCase().contains(query.toLowerCase()) ||
              employee['branch'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: "Search Employees",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: filterEmployees,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredEmployees.isEmpty
                    ? const Center(child: Text("No employees found"))
                    : ListView.builder(
                        itemCount: filteredEmployees.length,
                        itemBuilder: (context, index) {
                          final employee = filteredEmployees[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(employee["name"]),
                              subtitle: Text(
                                  "Role: ${employee["role"]} | Branch: ${employee["branch"]}"),
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                // Future: Add Employee Profile Navigation
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// 📌 Onboarding Process (Stepper UI)
class OnboardingTab extends StatefulWidget {
  const OnboardingTab({super.key});

  @override
  _OnboardingTabState createState() => _OnboardingTabState();
}

class _OnboardingTabState extends State<OnboardingTab> {
  int currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("New Employee Onboarding",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: currentStep,
              onStepContinue: () {
                if (currentStep < 3) {
                  setState(() => currentStep += 1);
                }
              },
              onStepCancel: () {
                if (currentStep > 0) {
                  setState(() => currentStep -= 1);
                }
              },
              steps: [
                Step(
                  title: const Text("Step 1: Personal Details"),
                  content: Column(
                    children: [
                      TextField(
                          decoration: InputDecoration(labelText: "Full Name")),
                      TextField(
                          decoration: InputDecoration(labelText: "Email")),
                      TextField(
                          decoration:
                              InputDecoration(labelText: "Phone Number")),
                    ],
                  ),
                  isActive: currentStep >= 0,
                  state:
                      currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text("Step 2: Upload Documents"),
                  content: Column(
                    children: [
                      ElevatedButton(
                          onPressed: () {}, child: const Text("Upload ID")),
                      ElevatedButton(
                          onPressed: () {},
                          child: const Text("Upload Address Proof")),
                    ],
                  ),
                  isActive: currentStep >= 1,
                  state:
                      currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text("Step 3: HR Approval"),
                  content: const Text("Awaiting HR verification and approval."),
                  isActive: currentStep >= 2,
                  state:
                      currentStep > 2 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: const Text("Step 4: Welcome!"),
                  content: const Text("Onboarding completed successfully!"),
                  isActive: currentStep >= 3,
                  state:
                      currentStep == 3 ? StepState.complete : StepState.indexed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 📌 Requests Tab
class RequestsTab extends StatelessWidget {
  const RequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Requests (Employees can submit requests)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}

// 📌 Employee Suggestions Tab
class SuggestionsTab extends StatelessWidget {
  const SuggestionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Suggestions Board (Employees can submit ideas)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}

// 📌 HR Documents Tab
class DocumentsTab extends StatelessWidget {
  const DocumentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("HR Documents (Contracts, Policies, etc.)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}
