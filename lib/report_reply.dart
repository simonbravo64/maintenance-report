import 'package:dorm_maintenance_reporter/dm_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// For date formatting

class ReplyToReportPage extends StatefulWidget {
  final String reportId;

  const ReplyToReportPage({super.key, required this.reportId});

  @override
  ReplyToReportPageState createState() => ReplyToReportPageState();
}

class ReplyToReportPageState extends State<ReplyToReportPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  DateTime? dateArrival;
  TimeOfDay? timeArrival;

  // Format date to display in TextFormField
  String get _formattedDate =>
      dateArrival != null ? "${dateArrival!.year}-${dateArrival!.month.toString().padLeft(2, '0')}-${dateArrival!.day.toString().padLeft(2, '0')}" : "Select Date";

  // Format time to display in TextFormField
  String get _formattedTime =>
      timeArrival != null ? "${timeArrival!.hour.toString().padLeft(2, '0')}:${timeArrival!.minute.toString().padLeft(2, '0')}" : "Select Time";

  // Function to pick a date
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        dateArrival = pickedDate;
      });
    }
  }

  // Function to pick a time
  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        timeArrival = pickedTime;
      });
    }
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
  void initState() {
    super.initState();
    _fetchUserData();
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

               TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Expected Date of Action",
                  hintText: _formattedDate,
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Expected Time of Action",
                  hintText: _formattedTime,
                ),
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    String name = _name;
                    _replyToReport(name, _formattedDate, _formattedTime);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReportViewingPage()));
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

  Future<void> _replyToReport(String _name, String dateArrival, String timeArrival) async {
    await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({
      'personnel': _name,
      'date_arrival': dateArrival,
      'time_arrival': timeArrival,
      'status': 'Action Ongoing',
    });
  }
}
