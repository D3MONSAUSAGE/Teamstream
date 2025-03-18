import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:teamstream/services/pocketbase/clock_in_service.dart';
import 'timecard_confirmation_page.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

class TimecardPage extends StatefulWidget {
  const TimecardPage({super.key});

  @override
  State<TimecardPage> createState() => _TimecardPageState();
}

class _TimecardPageState extends State<TimecardPage> {
  final _codeController = TextEditingController();
  String? _errorMessage;
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  String? _action; // "clock-in" or "clock-out"
  bool _isLoading = false; // Track loading state for submit button
  bool _isMapInitialized = false; // Track if the map has been initialized

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _action = ClockInService.currentClockInRecordId == null
        ? "clock-in"
        : "clock-out";
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await ClockInService.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      if (_isMapInitialized && _mapController != null) {
        _mapController!
            .animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 15));
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to get location: $e";
        _currentPosition = null; // Ensure position is null on failure
      });
    }
  }

  Future<bool> _requestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _errorMessage = "Location permissions are denied";
        });
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage =
            "Location permissions are permanently denied, we cannot request permissions.";
      });
      return false;
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return true;
    }
    return false;
  }

  Future<void> _handleSubmit() async {
    if (_currentPosition == null) {
      setState(() {
        _errorMessage = "Please wait for location to load or check permissions";
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      if (_action == "clock-in") {
        await ClockInService.clockIn(
          _codeController.text,
          onSuccess: (recordId, latitude, longitude, clockInTime) {
            setState(() {
              _action = "clock-out";
              _isLoading = false;
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TimecardConfirmationPage(
                  action: "Clock In",
                  latitude: latitude,
                  longitude: longitude,
                  time: clockInTime,
                ),
              ),
            );
          },
        );
      } else if (_action == "clock-out") {
        await ClockInService.clockOut(
          _codeController.text,
          onSuccess: (recordId, latitude, longitude) {
            setState(() {
              _action = "clock-in";
              _isLoading = false;
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TimecardConfirmationPage(
                  action: "Clock Out",
                  latitude: latitude,
                  longitude: longitude,
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current local time for comparison
    final currentTime = DateTime.now();
    print(
        "🔍 Current local time: $currentTime, offset: ${currentTime.timeZoneOffset}");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Timecard",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _action == 'clock-in'
                            ? "Clock In to Start"
                            : "Clock Out to End",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      Icon(
                        _action == 'clock-in' ? Icons.login : Icons.logout,
                        color: Colors.blueAccent,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enter your Code",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        hintText: "Enter your code here",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.blueAccent, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.blueAccent, width: 2),
                        ),
                        errorText: _errorMessage,
                        errorStyle:
                            GoogleFonts.poppins(color: Colors.redAccent),
                      ),
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              FadeInUp(
                duration: const Duration(milliseconds: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your Current Location",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _currentPosition == null
                            ? const Center(
                                child: Text(
                                  "Failed to load location. Please enable location services.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              )
                            : GoogleMap(
                                onMapCreated: (controller) {
                                  _mapController = controller;
                                  _isMapInitialized = true;
                                  if (_currentPosition != null) {
                                    _mapController!.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                          _currentPosition!, 15),
                                    );
                                  }
                                },
                                initialCameraPosition: CameraPosition(
                                  target: _currentPosition ??
                                      const LatLng(37.7749,
                                          -122.4194), // Default to San Francisco if location fails
                                  zoom: 15,
                                ),
                                markers: _currentPosition != null
                                    ? {
                                        Marker(
                                          markerId: const MarkerId(
                                              "timecard_location"),
                                          position: _currentPosition!,
                                          icon: BitmapDescriptor
                                              .defaultMarkerWithHue(
                                                  BitmapDescriptor.hueAzure),
                                        ),
                                      }
                                    : {},
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _action == "clock-in" ? "Clock In" : "Clock Out",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Display Current Time for Reference
              FadeInUp(
                duration: const Duration(milliseconds: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Time: ${DateFormat('MMM d, h:mm a').format(currentTime)}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Recent Clock Records Section
              FadeInUp(
                duration: const Duration(milliseconds: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recent Clock Records (Last 24 Hours)",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: ClockInService.fetchRecentClockRecords(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.blueAccent,
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(
                            "Error loading records: ${snapshot.error}",
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          );
                        }
                        final records = snapshot.data ?? [];
                        if (records.isEmpty) {
                          return Text(
                            "No clock records in the last 24 hours.",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final record = records[index];
                            print("Record $index: $record");

                            // Safely parse clock-in time with manual offset
                            DateTime? clockInTime;
                            try {
                              String clockInTimeStr = record['time'];
                              if (!clockInTimeStr.contains('.')) {
                                clockInTimeStr = "$clockInTimeStr.000";
                              }
                              // Parse as local time and apply manual offset if needed
                              clockInTime =
                                  DateTime.parse(clockInTimeStr).toLocal();
                              // Apply manual offset to correct for 6-hour difference (e.g., 2:08 PM to 8:08 PM)
                              clockInTime =
                                  clockInTime.add(const Duration(hours: 6));
                              print(
                                  "🔍 Parsed clock-in time: $clockInTime, original: $clockInTimeStr");
                            } catch (e) {
                              print(
                                  "❌ Error parsing clock-in time: $e, raw value: ${record['time']}");
                              clockInTime = null;
                            }

                            // Safely parse clock-out time with manual offset
                            DateTime? clockOutTime;
                            if (record['clock_out_time'] != null &&
                                record['clock_out_time'].isNotEmpty) {
                              try {
                                String clockOutTimeStr =
                                    record['clock_out_time'];
                                if (!clockOutTimeStr.contains('.')) {
                                  clockOutTimeStr = "$clockOutTimeStr.000";
                                }
                                // Parse as local time and apply manual offset
                                clockOutTime =
                                    DateTime.parse(clockOutTimeStr).toLocal();
                                // Apply manual offset to correct for 6-hour difference
                                clockOutTime =
                                    clockOutTime.add(const Duration(hours: 6));
                                print(
                                    "🔍 Parsed clock-out time: $clockOutTime, original: $clockOutTimeStr");
                              } catch (e) {
                                print(
                                    "❌ Error parsing clock-out time: $e, raw value: ${record['clock_out_time']}");
                                clockOutTime = null;
                              }
                            }

                            final clockInLocation = record['latitude'] !=
                                        null &&
                                    record['longitude'] != null
                                ? "(${record['latitude']}, ${record['longitude']})"
                                : "Unknown";
                            final clockOutLocation = record[
                                            'clock_out_latitude'] !=
                                        null &&
                                    record['clock_out_longitude'] != null
                                ? "(${record['clock_out_latitude']}, ${record['clock_out_longitude']})"
                                : "Not clocked out yet";

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clockInTime != null
                                        ? "Clock In: ${DateFormat('MMM d, h:mm a').format(clockInTime)}"
                                        : "Clock In: Invalid date",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                  Text(
                                    "Location: $clockInLocation",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    clockOutTime != null
                                        ? "Clock Out: ${DateFormat('MMM d, h:mm a').format(clockOutTime)}"
                                        : "Clock Out: Not yet",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                  Text(
                                    clockOutTime != null
                                        ? "Location: $clockOutLocation"
                                        : "",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
