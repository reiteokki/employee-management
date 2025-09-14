import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/members_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _loading = true;
  List<dynamic> _hierarchy = [];

  @override
  void initState() {
    super.initState();
    _fetchHierarchy();
  }

  Future<void> _fetchHierarchy() async {
    try {
      final data = await MembersService.getHierarchy();
      setState(() {
        _hierarchy = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Hierarchy error: $e");
      setState(() => _loading = false);
    }
  }

  void _showMemberDetail(Map<String, dynamic> member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                member["NamaEPD"] ?? "-",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Branch: ${member["m_branch_id"] ?? "-"}",
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(height: 24),

              // Details
              _detailRow("GEPD", member["NamaGEPD"]),
              _detailRow("EPD", member["m_mst_epd"]),
              _detailRow("Name", member["m_name"]),
              const SizedBox(height: 24),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: navigate to update screen
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Update"),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Confirm Delete"),
                        content: Text(
                          "Are you sure you want to delete ${member["m_name"] ?? "this member"}?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      Navigator.pop(context);

                      final memberId = member["m_mst_id"];
                      if (memberId == null || memberId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Member ID not found")),
                        );
                        return;
                      }

                      final success = await MembersService.softDeleteMember(
                        memberId,
                      );

                      if (success) {
                        setState(() {
                          _hierarchy.removeWhere(
                            (e) => e["m_mst_id"] == memberId,
                          );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${member["m_name"]} deleted"),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Failed to delete member"),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper widget for detail rows
  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(child: Text(value?.toString() ?? "-")),
        ],
      ),
    );
  }

  Future<void> _exportToExcel() async {
    if (_hierarchy.isEmpty) return;

    final excel = Excel.createExcel();
    final sheet = excel['Hierarchy'];

    sheet.appendRow([
      "mm_mst_gepd",
      "NamaGEPD",
      "m_mst_epd",
      "NamaEPD",
      "Branch",
      "Name",
    ]);

    for (var row in _hierarchy) {
      sheet.appendRow([
        row["mm_mst_gepd"] ?? "",
        row["NamaGEPD"] ?? "",
        row["m_mst_epd"] ?? "",
        row["NamaEPD"] ?? "",
        row["m_branch_id"] ?? "",
        row["m_name"] ?? "",
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/hierarchy.xlsx";

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Excel exported to $filePath")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _hierarchy.isEmpty
          ? const Center(child: Text("No data available"))
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchHierarchy,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text("mm_mst_gepd")),
                            DataColumn(label: Text("NamaGEPD")),
                            DataColumn(label: Text("m_mst_epd")),
                            DataColumn(label: Text("NamaEPD")),
                            DataColumn(label: Text("Branch")),
                            DataColumn(label: Text("Name")),
                          ],
                          showCheckboxColumn: false,
                          rows: _hierarchy.map((row) {
                            return DataRow(
                              cells: [
                                DataCell(Text(row["mm_mst_gepd"] ?? "")),
                                DataCell(Text(row["NamaGEPD"] ?? "")),
                                DataCell(Text(row["m_mst_epd"] ?? "")),
                                DataCell(Text(row["NamaEPD"] ?? "")),
                                DataCell(Text(row["m_branch_id"] ?? "")),
                                DataCell(Text(row["m_name"] ?? "")),
                              ],
                              onSelectChanged: (_) => _showMemberDetail(row),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Export button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exportToExcel,
                      icon: const Icon(Icons.download),
                      label: const Text("Export to Excel"),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
