import 'package:dorm_maintenance_reporter/material_page.dart';
import 'package:dorm_maintenance_reporter/report_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:firebase_auth/firebase_auth.dart'; // For user roles
import 'report_reply.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class ReportViewingPage extends StatefulWidget {
  const ReportViewingPage({super.key});

  @override
  _ReportViewingPageState createState() => _ReportViewingPageState();
}

class _ReportViewingPageState extends State<ReportViewingPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userRole = 'none'; // Hold the user role


  @override
  void initState() {
    super.initState();
    _getUserRole();
    
      @override
      Widget build(BuildContext context) {
        throw UnimplementedError();
      }
  }


  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); 
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                '/login', 
                (Route<dynamic> route) => false,
                ); // Clear all previous routes
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  // Function to get the user's role from Firestore
  Future<void> _getUserRole() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _userRole = userDoc['role']; // Assign the role to the _userRole variable
        
      });
    }
  }
  
  Future<void> _refreshReports() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate a short delay for the refresh
    setState(() {}); // Rebuilds the widget to show updated content
  }


  // Function to get the reports from Firestore
  Stream<QuerySnapshot> _getReportStream() {
    return FirebaseFirestore.instance
        .collection('reports')
        .where('status') // Filter reports
        .snapshots();
  }
  String capitalizeEachWord(String sentence) {
  if (sentence.isEmpty) return sentence;
  return sentence.split('_').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
  }
  User? currentUser = FirebaseAuth.instance.currentUser;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              String? role = snapshot.data!['role'];
              if (role != null) {
                // Capitalize the role if available
                role = capitalizeEachWord(role);
                return Text("Reports - $role");
              }
            }
            return const Text("Reports"); // Default title if role is unavailable
          },
        ),
        automaticallyImplyLeading: false, // Remove the default back button
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutConfirmation(context);
            }
          )
        ]
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReports,
      child: StreamBuilder<QuerySnapshot>(
        stream: _getReportStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No reports available.'));
          }


          Map<String, List<DocumentSnapshot>> groupedReports = {
            'Pending': [],
            'Approved by SSD': [],
            'Inspected by Maintenance Supervisor': [],
            'Action Ongoing': [],
            'Resolved': [],
          };
          
          for (var doc in snapshot.data!.docs) {
            String status = doc['status'] ?? 'Pending';
            if (groupedReports.containsKey(status)) {
              groupedReports[status]?.add(doc);
            }
          }

          return ListView(
            children: groupedReports.entries.map((entry) {
              String status = entry.key;
              List<DocumentSnapshot> reports = entry.value;

              return reports.isNotEmpty
                  ? ExpansionTile(
                      title: Text('$status(${reports.length})'),
                      initiallyExpanded: status == 'Pending',
                      children: reports.map((report) {
                        String service = report['service'];
                        String time = report['time'];
                        Timestamp timestamp = report['date'];
                        DateTime date = timestamp.toDate();
                        String formattedDate = DateFormat('MM/dd/yyyy').format(date);
                        
                        return ListTile(
                          title: Text(service),
                          subtitle: Text('Date: $formattedDate, Time: $time'),
                          onTap: () {
                            // Navigate to the report detail page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportDetailPage(reportId: report.id), // Pass report ID to detail page
                              ),
                            );
                          },
                        );
                  }).toList(),
                )
              : const SizedBox.shrink();
            }).toList(),
          );
        },
      ),
      ),
    floatingActionButton: _userRole == 'dorm_manager' 
          ? FloatingActionButton(
              onPressed: () {
                // Navigate to the report submission page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportSubmissionPage(),
                  ),
                );
              },
              tooltip: 'Submit a new report',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class ReportDetailPage extends StatefulWidget {
  final String reportId;

  ReportDetailPage({required this.reportId});

  @override
  _ReportDetailPageState createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's role
  Future<String> _getUserRole() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return userDoc['role'];
    }
    return 'none';
  }


  // Mark the report as resolved
  Future<void> _markAsResolved() async {
    await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({
      'status': 'Resolved',
      'date_resolved': Timestamp.now(),
      'time_resolved': DateFormat('HH:mm').format(DateTime.now()),
    });
  }
  
  // confirmation from ssd
  Future<void> _markAsApproved() async {
    await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({
      'status': 'Approved by SSD',
      'date_approved': Timestamp.now(),
      'time_approved': DateFormat('HH:mm').format(DateTime.now()),
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('reports').doc(widget.reportId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        var report = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Report Details'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reported by: ${report['name'] ?? 'Unknown'}'),
                Text('Service Requested: ${report['service'] ?? 'Unknown'}'),
                Text('Details: ${report['details'] ?? 'No details provided'}'),
                Text('Dorm: ${report['dorm'] ?? 'Unknown'}'),
                const Text('Location Details:'),
                Text('Floor: ${report['floor'] ?? 'Unknown'}'),
                Text('Room: ${report['room'] ?? 'Unknown'}'),
                Text('Status: ${report['status'] ?? 'Unknown'}'),
                Text('Date Sent: ${DateFormat('yyyy-MM-dd').format(report['date'].toDate())}'),
                Text('Time Sent: ${report['time'] ?? 'Unknown'}'),
                if (report['status'] == "Approved by SSD") ...[
                  const Divider(),
                  Text("Approved by: ${report['name'] ?? 'N/A'}"),
                  Text("Date of Approval: ${DateFormat('yyyy-MM-dd').format(report['date_approved'].toDate())}"),
                  Text("Time of Approval: ${report['time_approved'] ?? 'N/A'}"),
                ],
                if (report['status'] == "Action Ongoing") ...[
                  const Divider(),
                  Text("Response by: ${report['name'] ?? 'N/A'}"),
                  Text("Expected Date of Action: ${report['date_arrival']}" ),
                  Text("Expected Time of Action: ${report['time_arrival'] ?? 'N/A'}"),
                ],
                if (report['status'] == "Resolved") ...[
                  const Divider(),
                  Text("Date Resolved: ${DateFormat('yyyy-MM-dd').format(report['date_resolved'].toDate())}"),
                  Text("Time Resolved: ${report['time_resolved'] ?? 'N/A'}"),
                ],

                FutureBuilder<String>(
                  future: _getUserRole(),
                  builder: (context, roleSnapshot) {
                    if (!roleSnapshot.hasData) {
                      return Container();
                    }

                    String userRole = roleSnapshot.data!;

                    // Show "Reply" button only for users with the "maintenance" role
                    if (userRole == 'maintenance' && report['status'] == 'Pending') {
                      return ElevatedButton(
                        onPressed: () {
                          // Navigate to Reply page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReplyToReportPage(reportId: widget.reportId)), 
                          );
                        },
                        child: const Text('Reply to Request'),
                      );
                    }

                    if (userRole == 'maintenance_supervisor' && report['status'] == 'Action Ongoing') {
                      return ElevatedButton(
                        onPressed: () {
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SupplyMaterialPage(reportId: widget.reportId, role: userRole,)), 
                          );
                        },
                        child: const Text('Reply to Request'),
                      );
                    }

                    // Show "Mark as Resolved" button only for users with the "dorm_manager" role
                    if (userRole == 'dorm_manager' && report['status'] == 'Action Ongoing') {
                      return ElevatedButton(
                        onPressed: () async {
                          // Show confirmation dialog
                          bool confirmed = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm'),
                              content: const Text('Mark this report as resolved?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );

                          // If confirmed, mark as resolved
                          if (confirmed) {
                            _markAsResolved();
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Mark as Resolved'),
                      );
                    }

                    // Show "Approve Report" button only for users with the "SSD" role
                    if (userRole == 'SSD' && report['status'] == 'Pending') {
                      return ElevatedButton(
                        onPressed: () async {
                          // Show confirmation dialog
                          bool confirmed = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm'),
                              content: const Text('Approve this report?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );

                          // If confirmed, mark as resolved
                          if (confirmed) {
                            _markAsApproved();
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Approve Report'),
                      );
                    }

                    return Container(); // Return an empty container if no button should be shown
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
