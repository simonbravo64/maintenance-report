import 'package:dorm_maintenance_reporter/dm_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class FollowUpReportPage extends StatefulWidget {
  final String reportId;

  const FollowUpReportPage({super.key, required this.reportId});

  @override
  FollowUpReportPageState createState() => FollowUpReportPageState();
}

class FollowUpReportPageState extends State<FollowUpReportPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  final TextEditingController _remarksController = TextEditingController();
  bool _isLoading = false;

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
      appBar: AppBar(title: const Text('Follow Up on Remarks')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _remarksController,
                      decoration: const InputDecoration(
                          labelText: 'Remarks', counterText: ''),
                      maxLength: 250,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(250)
                      ],
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
                          setState(() => _isLoading = true);
                          await _followUpOnReport(_name, _remarksController.text);
                          if (mounted) {
                            setState(() => _isLoading = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReportViewingPage(),
                              ),
                            );
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

  Future<void> _followUpOnReport(String dmName, String remarks) async {
    try {
      DocumentSnapshot reportDoc = await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .get();

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .update({
        'dm': dmName,
        'dm_remarks': remarks,
        'status': 'Followed-Up by DM',
      });

      String reportTitle = reportDoc['title'] ?? 'Report';

      List<String> adminEmails = await _fetchAdminEmails();

      if (adminEmails.isNotEmpty) {
        await _sendEmailNotification(adminEmails, dmName, remarks, reportTitle);
      }
    } catch (e) {
      print('Error following up on report: $e');
    }
  }

  Future<List<String>> _fetchAdminEmails() async {
    List<String> emails = [];
    try {
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
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

  Future<void> _sendEmailNotification(
    List<String> recipientEmails,
    String dmName,
    String remarks,
    String reportTitle,
  ) async {
    String username = "dormmaintenancereporthub@gmail.com";
    String password = "qplwtaaptzornudb";

    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Dorm Maintenance Report Hub')
      ..recipients.addAll(recipientEmails)
      ..subject = 'Follow-Up on Report: $reportTitle'
      ..text = '''
$dmName has followed up on the report "$reportTitle".

Remarks: $remarks

''';

    try {
      await send(message, smtpServer);
      print('✅ Email sent successfully to all admins.');
    } catch (e) {
      print('❌ Failed to send email: $e');
    }
  }
}
