import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teamstream/services/pocketbase/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  void login() async {
    setState(() {
      isLoading = true;
    });

    final response = await AuthService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (response != null) {
      final String userId = response["userId"]!;
      final String userRole = response["role"]!;

      AuthService.setLoggedInUser(userId, userRole);
      print("✅ Successfully logged in. User ID: $userId | Role: $userRole");

      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      print("❌ Login failed. No user ID or role retrieved.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Invalid email or password", style: GoogleFonts.poppins()),
          backgroundColor: Colors.red, // Match error style
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Match ManagerDashboardPage
      appBar: AppBar(
        title: Text(
          'Login',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.blueAccent, // Match ManagerDashboardPage
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              12, 24, 12, 16), // Match ManagerDashboardPage padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent
                      .withOpacity(0.1), // Match ManagerDashboardPage
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent
                          .withOpacity(0.2), // Match ManagerDashboardPage
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock,
                  size: 60,
                  color: Colors.blueAccent, // Match ManagerDashboardPage
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                "Welcome Back",
                style: GoogleFonts.poppins(
                  fontSize: 26, // Match ManagerDashboardPage header
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900], // Match ManagerDashboardPage
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Login to continue",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600], // Match ManagerDashboardPage
                ),
              ),
              const SizedBox(height: 30),

              // Email Field
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email,
                      color: Colors.blueAccent), // Match ManagerDashboardPage
                  labelText: "Email",
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                  filled: true,
                  fillColor: Colors
                      .white, // Match ManagerDashboardPage card background
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12), // Match ManagerDashboardPage
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.grey[300]!), // Match ManagerDashboardPage
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Colors.blueAccent), // Match ManagerDashboardPage
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock,
                      color: Colors.blueAccent), // Match ManagerDashboardPage
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.blueAccent, // Match ManagerDashboardPage
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  labelText: "Password",
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                  filled: true,
                  fillColor: Colors
                      .white, // Match ManagerDashboardPage card background
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.grey[300]!), // Match ManagerDashboardPage
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Colors.blueAccent), // Match ManagerDashboardPage
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 10),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _showSnackBar('Forgot Password feature coming soon!');
                  },
                  child: Text(
                    "Forgot Password?",
                    style: GoogleFonts.poppins(
                        color: Colors.blueAccent), // Match ManagerDashboardPage
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.blueAccent, // Match ManagerDashboardPage
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          12), // Match ManagerDashboardPage
                    ),
                    elevation: 2, // Match ManagerDashboardPage card elevation
                    shadowColor: Colors.grey
                        .withOpacity(0.2), // Match ManagerDashboardPage
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          "Login",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w500, // Match ManagerDashboardPage
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

  void _showSnackBar(String message,
      {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: isSuccess
            ? Colors.green
            : (isError
                ? Colors.red
                : Colors.blueAccent), // Match ManagerDashboardPage
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
