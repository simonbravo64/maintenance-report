import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportSubmissionPage extends StatefulWidget {
  const ReportSubmissionPage({super.key});

  @override
  ReportSubmissionPageState createState() => ReportSubmissionPageState();
}

class ReportSubmissionPageState extends State<ReportSubmissionPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  // User data from Firestore
  String _name = '';
  String _dormLocation = 'Select...'; // Default value
  

  // Fetch user details from Firestore
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

  // Function to submit the report
  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      DateTime now = DateTime.now();
      String date = DateFormat('yyyy-MM-dd').format(now);
      String time = DateFormat('HH:mm').format(now);
      String name = _name;

      try {
        await FirebaseFirestore.instance.collection('reports').add({
          'name': name, // Name fetched from the user's document
          'title': _titleController.text,
          'date': now, // Store the date as a timestamp
          'time': time, // Store time as a string
          'details': _detailsController.text,
          'dorm': _dormLocation,
          'floor': _floorController.text,
          'room': _roomController.text,
          'status': 'New', // Default status
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report Submitted Successfully')),
          );
          
          Navigator.pop(context); // Go back to the previous page
        }
      } catch (e) {
        // Show error message if the widget is still mounted
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting report: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit a Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter title';
                  }
                  return null;
                },
              ),
              
              TextFormField(
                controller: _detailsController,
                decoration: const InputDecoration(labelText: 'Details'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter details';
                  }
                  return null;
                },
              ),
              // Dropdown for dorm selection
              DropdownButtonFormField<String>(
                value: _dormLocation,
                decoration: const InputDecoration(labelText: 'Dorm'),
                items: ['Select...','Dorm 1', 'Dorm 2', 'Dorm 3'].map((dorm) {
                  return DropdownMenuItem(
                    value: dorm,
                    child: Text(dorm),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _dormLocation = value!;
                  });
                },
              ),
              TextFormField(
                controller: _floorController,
                decoration: const InputDecoration(labelText: 'Floor'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the floor';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(labelText: 'Room'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the room';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitReport,
                child: const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
