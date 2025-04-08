import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:dorm_maintenance_reporter/dm_page.dart';

class ReplyToReportPage extends StatefulWidget {
  final String reportId;

  const ReplyToReportPage({super.key, required this.reportId});

  @override
  ReplyToReportPageState createState() => ReplyToReportPageState();
}

class ReplyToReportPageState extends State<ReplyToReportPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';

  final TextEditingController _remarksController = TextEditingController();
  String _status = 'Select...'; 

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        setState(() {
          _name = userDoc['name'] ?? 'Anonymous';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reply to Report')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status of Report'),
                items: ['Select...', 'Pending', 'Addressed', 'Cancelled', 'Denied'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: 'Remarks'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter remarks';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String name = _name;
                    await _replyToReport(name, _remarksController.text, _status);
                    if (mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReportViewingPage()));
                    }
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _replyToReport(String adminName, String remarks, String newStatus) async {
    try {
      // Fetch report data to get the user's email and report title
      DocumentSnapshot reportDoc = await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).get();

      if (reportDoc.exists) {
        
        String reportTitle = reportDoc['title'] ?? 'Report';

        // Update Firestore with new report details
        await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({
          'admin': adminName,
          'admin_remarks': remarks,
          'status': newStatus,
        });

        // Fetch all Dorm Manager emails
        List<String> dmEmails = await _fetchDormManagerEmails();

        // Send Email Notification to all Dorm Managers
        if (dmEmails.isNotEmpty) {
          await _sendEmailNotification(dmEmails, adminName, newStatus, remarks, reportTitle);
        }
      }
    } catch (e) {
      print('Error replying to report: $e');
    }
  }

  Future<List<String>> _fetchDormManagerEmails() async {
    List<String> emails = [];
    try {
      QuerySnapshot dmSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'user') // Get users with role "user"
          .get();

      for (var doc in dmSnapshot.docs) {
        String? email = doc['email'];
        if (email != null && email.isNotEmpty) {
          emails.add(email);
        }
      }
    } catch (e) {
      print('Error fetching Dorm Manager emails: $e');
    }
    return emails;
  }

  Future<void> _sendEmailNotification(
      List<String> recipientEmails, String adminName, String newStatus, String remarks, String reportTitle) async {
    
    String senderEmail = "spbravo@brc.pshs.edu.ph"; // Your email
    String appPassword = "wkzsrtmdttpabrwp"; // Your Gmail app password

    final smtpServer = gmail(senderEmail, appPassword);

    final message = Message()
      ..from = Address(senderEmail, 'Dorm Maintenance Report Hub')
      ..recipients.addAll(recipientEmails)
      ..subject = 'Report Updated: $reportTitle'
      ..text = '''
A report titled "$reportTitle" has been updated by $adminName.

New Status: $newStatus
Remarks: $remarks


''';

    try {
      await send(message, smtpServer);
      print('✅ Email sent successfully to Dorm Managers.');
    } catch (e) {
      print('❌ Failed to send email: $e');
    }
  }
}
