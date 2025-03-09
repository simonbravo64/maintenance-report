// lib/material_request_container.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MaterialLaborContainer extends StatefulWidget {
  final String materials;
  final String reportId;
  final String role;
  const MaterialLaborContainer({
    Key? key,
    required this.materials,
    required this.reportId,
    required this.role,
  }) : super(key: key);

  @override
  _MaterialLaborContainerState createState() =>
      _MaterialLaborContainerState(this.role);
}

class _MaterialLaborContainerState extends State<MaterialLaborContainer> {
  bool isExpanded = false;
  bool existing = false;
  String remarks = '';

  _MaterialLaborContainerState(String role) {
    isExpanded = role == 'SAO';
  }

  void onSetRemarks(String remarks) {
    setState(() {
      this.remarks = remarks;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchMaterialsData();
  }

  Future<void> _fetchMaterialsData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('materials')
          .doc(widget.materials)
          .get();
      if (snapshot.exists) {
        var materials = snapshot.data() as Map<String, dynamic>;
        onSetRemarks(materials['sao_remarks'] ?? '');
        setState(() {
          existing = true;
        }); // Update the UI after data is fetched
      }
    } catch (e) {
      print("Error fetching materials data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var remarksController = TextEditingController(text: remarks);
    return Column(
      children: !existing
          ? []
          : [
              ExpansionTile(
                initiallyExpanded: isExpanded,
                title: const Text('Workforce Management'),
                trailing: Icon(
                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                onExpansionChanged: (bool expanded) {
                  setState(() {
                    isExpanded = expanded;
                  });
                },
                children: isExpanded
                    ? [
                        TextField(
                          enabled: widget.role == 'SAO',
                          controller: remarksController,
                          maxLines: null,
                          decoration: const InputDecoration(
                            labelText: 'SAO Remarks',
                            border: OutlineInputBorder(),
                          ),
                        )
                      ]
                    : [],
              ),
              if (widget.role == 'SAO')
                ElevatedButton(
                  onPressed: () async {},
                  child: const Text('Workforce ready'),
                ),
            ],
    );
  }
}
