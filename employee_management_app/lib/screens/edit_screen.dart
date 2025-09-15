import 'package:employee_management_app/services/superiors_service.dart';
import 'package:flutter/material.dart';
import '../services/members_service.dart';

class EditMemberScreen extends StatefulWidget {
  final Map<String, dynamic> member;
  final Future<void> Function()? onUpdate;

  const EditMemberScreen({super.key, required this.member, this.onUpdate});

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {};

  bool _loading = false;
  List<Map<String, dynamic>> _managers = [];

  @override
  void initState() {
    super.initState();
    _formData['m_name'] = widget.member['m_name'] ?? '';
    _formData['m_branch_id'] = widget.member['m_branch_id'] ?? '';
    _formData['m_manager_id'] = widget.member['m_manager_id'] ?? '';

    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final managers = await SuperiorsService.fetchSuperiors();

      setState(() {
        _managers = managers;
      });
    } catch (e) {
      debugPrint("Dropdown load error: $e");
    }
  }

  Future<void> _updateMember() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _loading = true);

    try {
      final success = await MembersService.updateMember(
        widget.member['m_mst_id'],
        _formData,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Member updated successfully")),
        );

        if (widget.onUpdate != null) {
          await widget.onUpdate!();
        }

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update member")),
        );
      }
    } catch (e) {
      debugPrint("Update member error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("An error occurred")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildTextField({required String label, required String keyName}) {
    return TextFormField(
      initialValue: _formData[keyName],
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$label is required";
        }
        return null;
      },
      onSaved: (value) => _formData[keyName] = value ?? '',
    );
  }

  Widget _buildDropdown({
    required String label,
    required String keyName,
    required List<Map<String, dynamic>> items,
    required String valueKey,
    required String textKey,
  }) {
    return DropdownButtonFormField<String>(
      value: _formData[keyName]?.isNotEmpty == true ? _formData[keyName] : null,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item[valueKey]?.toString(),
              child: Text(item[textKey]?.toString() ?? "-"),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() {
        _formData[keyName] = value ?? '';
      }),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$label is required";
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Member")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextField(label: "Name", keyName: "m_name"),
                    const SizedBox(height: 16),
                    _buildTextField(label: "Branch ID", keyName: "m_branch_id"),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: "Manager",
                      keyName: "m_manager_id",
                      items: _managers,
                      valueKey: "m_rep_id",
                      textKey: "m_name",
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateMember,
                        child: const Text("Update Member"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
