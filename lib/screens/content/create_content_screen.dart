import 'package:flutter/material.dart';
import '../../services/openclaw_dashboard_service.dart'; // OpenClaw v2.0
import '../../services/content_management_service.dart';

class CreateContentScreen extends StatefulWidget {
  final String world;
  const CreateContentScreen({super.key, required this.world});
  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _category;
  bool _isLoading = false;
  final List<String> _categories = ['Geschichte', 'Wissenschaft', 'Philosophie', 'Kunst', 'Technologie', 'Sonstiges'];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submitContent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final success = await ContentManagementService.createContent(
        world: widget.world, title: _titleController.text, body: _bodyController.text, category: _category,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Beitrag erfolgreich erstellt!'), backgroundColor: Colors.green));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Fehler beim Erstellen'), backgroundColor: Colors.red));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Neuer Beitrag')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titel', border: OutlineInputBorder()), validator: (v) => v == null || v.isEmpty ? 'Bitte Titel eingeben' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(initialValue: _category, decoration: const InputDecoration(labelText: 'Kategorie (optional)', border: OutlineInputBorder()), items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(), onChanged: (v) => setState(() => _category = v)),
            const SizedBox(height: 16),
            TextFormField(controller: _bodyController, decoration: const InputDecoration(labelText: 'Inhalt', border: OutlineInputBorder(), alignLabelWithHint: true), maxLines: 15, validator: (v) => v == null || v.isEmpty ? 'Bitte Inhalt eingeben' : null),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _isLoading ? null : _submitContent, style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)), child: _isLoading ? const CircularProgressIndicator() : const Text('Beitrag erstellen', style: TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }
}
