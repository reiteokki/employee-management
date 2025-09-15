import 'dart:io';
import 'package:employee_management_app/screens/create_member.dart';
import 'package:employee_management_app/screens/edit_screen.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/members_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _loading = true;
  List<dynamic> _hierarchy = [];
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _fetchHierarchy();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString("user_role");
    });
  }

  Future<void> _fetchHierarchy() async {
    setState(() => _loading = true);
    try {
      final data = await MembersService.getHierarchy();

      final transformed = data.map<Map<String, dynamic>>((row) {
        return {...row, "m_manager_id": row["m_mst_epd"]};
      }).toList();

      setState(() {
        _hierarchy = transformed;
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
              Text(
                member["m_name"] ?? "-",
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
              _detailRow("GEPD Name", member["NamaGEPD"]),
              _detailRow("EPD Name", member["NamaEPD"]),
              const SizedBox(height: 24),

              if (_userRole == "GEPD" || _userRole == "ADM") ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final updatedMember = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditMemberScreen(member: member),
                        ),
                      );

                      if (updatedMember != null) {
                        await _fetchHierarchy();
                      }
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text("Update"),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (_userRole == "GEPD" || _userRole == "ADM")
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
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
                            const SnackBar(
                              content: Text("Member ID not found"),
                            ),
                          );
                          return;
                        }

                        final success = await MembersService.softDeleteMember(
                          memberId,
                        );

                        if (success) {
                          await _fetchHierarchy();
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
    for (var sheet in excel.sheets.keys.toList()) {
      excel.delete(sheet);
    }

    final sheet = excel['Hierarchy'];

    sheet.appendRow([
      "Name",
      "Branch",
      "EPD Name",
      "EPD ID",
      "GEPD Name",
      "GEPD ID",
    ]);

    for (var row in _hierarchy) {
      sheet.appendRow([
        row["m_name"] ?? "",
        row["m_branch_id"] ?? "",
        row["NamaEPD"] ?? "",
        row["m_mst_epd"] ?? "",
        row["NamaGEPD"] ?? "",
        row["mm_mst_gepd"] ?? "",
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();

    final timestamp = DateTime.now().toIso8601String().replaceAll(":", "-");
    final filePath = "${directory.path}/hierarchy_$timestamp.xlsx";

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          if (_userRole == "GEPD" || _userRole == "ADM")
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: "Create Member",
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateMemberScreen()),
                );
                await _fetchHierarchy();
              },
            ),
        ],
      ),
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
                            DataColumn(label: Text("Name")),
                            DataColumn(label: Text("Branch")),
                            DataColumn(label: Text("EPD Name")),
                            DataColumn(label: Text("EPD ID")),
                            DataColumn(label: Text("GEPD Name")),
                            DataColumn(label: Text("GEPD ID")),
                          ],
                          showCheckboxColumn: false,
                          rows: _hierarchy.map((row) {
                            return DataRow(
                              cells: [
                                DataCell(Text(row["m_name"] ?? "")),
                                DataCell(Text(row["m_branch_id"] ?? "")),
                                DataCell(Text(row["NamaEPD"] ?? "")),
                                DataCell(Text(row["m_manager_id"] ?? "")),
                                DataCell(Text(row["NamaGEPD"] ?? "")),
                                DataCell(Text(row["mm_mst_gepd"] ?? "")),
                              ],
                              onSelectChanged: (_) => _showMemberDetail(row),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
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
