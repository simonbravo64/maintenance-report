import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:dorm_maintenance_reporter/dm_page.dart';
import 'package:flutter/services.dart'; 

class ReplyToReportPage extends StatefulWidget {
  final String reportId;

  const ReplyToReportPage({super.key, required this.reportId});

  @override
  ReplyToReportPageState createState() => ReplyToReportPageState();
}

class ReplyToReportPageState extends State<ReplyToReportPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String? _reporterEmail;
  bool _isLoading = false;

  final TextEditingController _remarksController = TextEditingController();
  String _status = 'Select...'; 

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchReporterEmail();
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

  Future<void> _fetchReporterEmail() async {
  try {
    DocumentSnapshot reportDoc = await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.reportId)
        .get();

    if (reportDoc.exists) {
      String reporterUid = reportDoc['user_uid'];
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(reporterUid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _reporterEmail = userDoc['email'];
        });
      }
    }
  } catch (e) {
    print('Error fetching updated reporter email: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reply to Report')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
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
                      decoration: const InputDecoration(
                        labelText: 'Remarks',
                        counterText: '',
                      ),
                      maxLength: 250,
                      inputFormatters: [LengthLimitingTextInputFormatter(250)],
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
                          await _replyToReport(_name, _remarksController.text, _status);
                          if (mounted) {
                            setState(() => _isLoading = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ReportViewingPage()),
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

  Future<void> _replyToReport(String adminName, String remarks, String newStatus) async {
    try {
      DocumentSnapshot reportDoc = await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).get();

      if (reportDoc.exists) {
        String reportTitle = reportDoc['title'] ?? 'Report';

        // Update Firestore with new report details
        await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({
          'admin': adminName,
          'admin_remarks': remarks,
          'status': newStatus,
        });

        if (_reporterEmail != null) {
          await _sendEmailNotification(_reporterEmail!, adminName, newStatus, remarks, reportTitle);
        }
      }
    } catch (e) {
      print('Error replying to report: $e');
    }
  }

  Future<void> _sendEmailNotification(
      String recipientEmail, String adminName, String newStatus, String remarks, String reportTitle) async {
    
    String senderEmail = "dormmaintenancereporthub@gmail.com"; 
    String appPassword = "qplwtaaptzornudb";

    final smtpServer = gmail(senderEmail, appPassword);

    final message = Message()
      ..from = Address(senderEmail, 'Dorm Maintenance Report Hub')
      ..recipients.add(recipientEmail)
      ..subject = 'Your Dorm Report Update: $reportTitle'
      ..text = '''
Your report titled "$reportTitle" has been updated by $adminName.

Status: $newStatus
Remarks: $remarks

''';

    try {
      await send(message, smtpServer);
      print('✅ Email sent successfully to $recipientEmail.');
    } catch (e) {
      print('❌ Failed to send email: $e');
    }
  }
}