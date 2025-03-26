
import 'package:dorm_maintenance_reporter/report_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:firebase_auth/firebase_auth.dart'; // For user roles
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'report_followup.dart';
import 'report_reply.dart';



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

  Color getFolderColor(String status) {
    switch (status) {
      case 'New':
        return Colors.orangeAccent; // Orange for new reports
      case 'Pending':
        return Colors.amber; // Yellow for pending reports
      case 'Addressed':
        return Colors.blueAccent; // Blue for addressed reports
      case 'Cancelled':
        return Colors.redAccent; // Red for cancelled reports
      case 'Denied':
        return Colors.grey; // Grey for denied reports
      case 'Followed-Up by DM':
        return Colors.purpleAccent; // Purple for followed-up reports
      case 'Resolved':
        return Colors.green; // Green for resolved reports
      default:
        return Colors.black12; // Default light grey
    }
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
            'New': [],
            'Pending': [],
            'Addressed': [],
            'Cancelled': [],
            'Denied': [],
            'Followed-Up by DM': [],
            'Resolved': [],
          };
          
          for (var doc in snapshot.data!.docs) {
            String status = doc['status'] ?? 'New';
            if (groupedReports.containsKey(status)) {
              groupedReports[status]?.add(doc);
            }
          }

          return ListView(
  children: groupedReports.entries.map((entry) {
    String status = entry.key;
    List<DocumentSnapshot> reports = entry.value;

    if (reports.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: getFolderColor(status), // Apply color based on status
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text('$status (${reports.length})'),
        initiallyExpanded: status == 'New',
        children: reports.asMap().entries.map((entry) {
          int index = entry.key;
          DocumentSnapshot report = entry.value;
          
          String service = report['title'];
          String time = report['time'];
          Timestamp timestamp = report['date'];
          DateTime date = timestamp.toDate();
          String formattedDate = DateFormat('MM/dd/yyyy').format(date);

          // Alternate row colors based on index
          Color rowColor = index.isEven ? Colors.grey[200]! : Colors.white;

          return Container(
            color: rowColor,
            child: ListTile(
              title: Text(service),
              subtitle: Text('Date: $formattedDate, Time: $time'),
              onTap: () {
                // Navigate to the report detail page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailPage(reportId: report.id),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
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

  Future<List<String>> _fetchAdminEmails() async {
    List<String> emails = [];
    try {
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin') // Filter for admin users
          .get();

      for (var doc in adminSnapshot.docs) {
        String? email = doc['email'];
        if (email != null && email.isNotEmpty) {
          emails.add(email);
        }
      }
    } catch (e) {
      print('Error fetching admin emails: $e');
    }
    return emails;
  }

  Future<void> _sendEmailNotification(List<String> recipientEmail, String reportTitle) async {
  String username = "spbravo@brc.pshs.edu.ph"; 
  String password = "wkzsrtmdttpabrwp"; // App password

  final smtpServer = gmail(username, password);

  final message = Message()
    ..from = Address(username, 'Dorm Maintenance Report Hub')
    ..recipients.add(recipientEmail)
    ..subject = 'Your Report has been Resolved'
    ..text = '''
Hello,

A report "$reportTitle" has been marked as resolved.

''';

  try {
    await send(message, smtpServer);
    print('✅ Email sent to $recipientEmail');
  } catch (e) {
    print('❌ Failed to send email: $e');
  }
}


  // Mark the report as resolved
  Future<void> _markAsResolved() async {
    DocumentSnapshot reportDoc = await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).get();
    await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({
      'status': 'Resolved',
      'date_resolved': Timestamp.now(),
      'time_resolved': DateFormat('HH:mm').format(DateTime.now()),
      
    });
    List<String> adminEmails = await _fetchAdminEmails();
    String reportTitle = reportDoc['title'] ?? 'Report';
      if (adminEmails.isNotEmpty) {
      await _sendEmailNotification(adminEmails, reportTitle);
      }
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
                Text('Title of Request: ${report['title'] ?? 'Unknown'}'),
                Text('Details: ${report['details'] ?? 'No details provided'}'),
                Text('Status: ${report['status'] ?? 'Unknown'}'),
                Text('Date Sent: ${DateFormat('yyyy-MM-dd').format(report['date'].toDate())}'),
                Text('Time Sent: ${report['time'] ?? 'Unknown'}'),
                if (report['imageUrl'] != null && report['imageUrl'].isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImage(imageUrl: report['imageUrl']),
                        ),
                      );
                    },
                    child: Center(
                      child: Hero(
                        tag: "imagePreview",
                        child: Image.network(
                          report['imageUrl'],
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                else
                  const Center(child: Text("No Image Provided", style: TextStyle(color: Colors.red))),
                
                if (report['status'] != "New" && report['status'] != "Resolved") ...[
                  const Divider(),
                  Text("Response by: ${report['admin'] ?? 'N/A'}"),
                  Text("Remarks: ${report['admin_remarks'] ?? 'N/A'}"),
                ],

                if (report['status'] == "Followed-Up by DM") ...[
                  const Divider(),
                  Text("Response by: ${report['dm'] ?? 'N/A'}"),
                  Text("Remarks: ${report['dm_remarks'] ?? 'N/A'}"),
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

                    // Show "Reply" button only for users with the "admin" role
                    if (userRole == 'admin' && (report['status'] == 'New' || report['status'] == 'Followed-Up by DM')) {
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
                    
                    List<Widget> actionButtons = [];

                    if (userRole == 'dorm_manager' && (report['status'] != 'New' && report['status'] != 'Resolved' && report['status'] != 'Followed-Up by DM')) {
                      actionButtons.add(
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowUpReportPage(reportId: widget.reportId),
                              ),
                             );
                          },
                          child: const Text('Follow Up'),
                        ),
                      );
                    }

                  // Show "Mark as Resolved" button only for users with the "dorm_manager" role
                    if (userRole == 'dorm_manager' && (report['status'] != 'New' && report['status'] != 'Resolved' && report['status'] != 'Followed-Up by DM')) {
                      actionButtons.add(
                        ElevatedButton(
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
                          ),
                        );
                      }

                      // Return a column with all the buttons
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: actionButtons,
                      );


                    


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

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for better visibility
      body: Stack(
        children: [
          Center(
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
          Positioned(
            top: 40, // Move button down for better placement
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6), // Background for visibility
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 30, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
