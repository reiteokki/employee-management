import 'package:flutter/material.dart';
import '../services/members_service.dart';
import '../services/superiors_service.dart';

class CreateMemberScreen extends StatefulWidget {
  const CreateMemberScreen({super.key});

  @override
  State<CreateMemberScreen> createState() => _CreateMemberScreenState();
}

class _CreateMemberScreenState extends State<CreateMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {};

  bool _loading = false;
  List<Map<String, dynamic>> _superiors = [];
  String? _selectedSuperior;

  @override
  void initState() {
    super.initState();
    _formData["m_current_position"] = "EPC";
    _loadSuperiors();
  }

  Future<void> _loadSuperiors() async {
    try {
      final data = await SuperiorsService.fetchSuperiors();
      if (data != null && data is List) {
        setState(() {
          _superiors = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint("Error loading superiors: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load superiors")));
    }
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_selectedSuperior != null) {
      _formData["m_manager_id"] = _selectedSuperior!;
    }

    setState(() => _loading = true);

    try {
      final success = await MembersService.createMember(_formData);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Member created successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create member")),
        );
      }
    } catch (e) {
      debugPrint("Create member error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("An error occurred")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required String keyName,
    String? initialValue,
    bool requiredField = true,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (requiredField && (value == null || value.isEmpty)) {
          return "$label is required";
        }
        return null;
      },
      onSaved: (value) {
        _formData[keyName] = value ?? "";
      },
    );
  }

  Widget _buildSuperiorDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: "Select EPD"),
      value: _selectedSuperior,
      items: _superiors.map((superior) {
        return DropdownMenuItem<String>(
          value: superior["m_rep_id"],
          child: Text(superior["m_name"] ?? ""),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSuperior = value;
        });
      },
      validator: (value) => value == null ? "Please select a superior" : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Member")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextField(label: "Member ID", keyName: "m_rep_id"),
                    _buildTextField(label: "Name", keyName: "m_name"),
                    _buildTextField(label: "Branch", keyName: "m_branch_id"),
                    const SizedBox(height: 16),
                    _buildSuperiorDropdown(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveMember,
                        child: const Text("Create Member"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
