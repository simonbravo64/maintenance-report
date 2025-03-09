// lib/material_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dorm_maintenance_reporter/material_availability_container.dart';
import 'package:dorm_maintenance_reporter/material_labor_container.dart';
import 'package:dorm_maintenance_reporter/material_request_container.dart';
import 'package:flutter/material.dart';

class SupplyMaterialPage extends StatefulWidget {
  final String reportId;
  final String role;
  const SupplyMaterialPage(
      {Key? key, required this.reportId, required this.role})
      : super(key: key);

  @override
  _SupplyState createState() => _SupplyState();
}

class _SupplyState extends State<SupplyMaterialPage> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('reports')
            .doc(widget.reportId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          var report = snapshot.data!.data() as Map<String, dynamic>;
          String materials = report['materials'] ?? '';

          return Scaffold(
              appBar: AppBar(
                title: const Text('Inspection Details'),
              ),
              body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        ExpansionTile(
                          title: const Text('Service'),
                          subtitle:
                              Text('${report['service'] ?? 'No Service'}'),
                          trailing: Icon(isExpanded
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down),
                          onExpansionChanged: (bool expanded) {
                            setState(() {
                              isExpanded = expanded;
                            });
                          },
                          children: [
                            if (isExpanded)
                              DataTable(columns: const <DataColumn>[
                                DataColumn(
                                    label: Expanded(
                                        child: Text('Key',
                                            style: TextStyle(
                                                fontStyle: FontStyle.italic)))),
                                DataColumn(
                                    label: Expanded(
                                        child: Text('Value',
                                            style: TextStyle(
                                                fontStyle: FontStyle.italic))))
                              ], rows: <DataRow>[
                                DataRow(cells: <DataCell>[
                                  const DataCell(Text('Service')),
                                  DataCell(Text('${report['service']}'))
                                ]),
                                DataRow(cells: <DataCell>[
                                  const DataCell(Text('Personnel')),
                                  DataCell(Text(
                                      '${report['personnel'] ?? 'Not assigned'}'))
                                ])
                              ])
                          ],
                        ),
                        MaterialRequestContainer(
                            materials: materials,
                            reportId: widget.reportId,
                            role: widget.role),
                        MaterialAvailabilityContainer(
                            materials: materials,
                            reportId: widget.reportId,
                            role: widget.role),
                        MaterialLaborContainer(
                            materials: materials,
                            reportId: widget.reportId,
                            role: widget.role)
                      ]))));
        });
  }
}
