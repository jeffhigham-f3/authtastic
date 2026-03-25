import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/password_item.dart';
import '../../../core/state/vault_controller.dart';

class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key, this.initialItem});

  final PasswordItem? initialItem;

  bool get isEditing => initialItem != null;

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _websiteController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialItem;
    if (initial != null) {
      _titleController.text = initial.title;
      _websiteController.text = initial.website ?? '';
      _usernameController.text = initial.username;
      _passwordController.text = initial.password;
      _notesController.text = initial.notes ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _websiteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generatePassword() {
    final generated = ref
        .read(vaultControllerProvider.notifier)
        .generatePassword();
    _passwordController.text = generated;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _saving = true);
    final controller = ref.read(vaultControllerProvider.notifier);
    final base = widget.initialItem;
    final entry = controller.buildPassword(
      id: base?.id,
      createdAt: base?.createdAt,
      title: _titleController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      website: _websiteController.text,
      notes: _notesController.text,
      category: base?.category,
    );

    if (widget.isEditing) {
      await controller.updatePassword(entry);
    } else {
      await controller.addPassword(entry);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Password' : 'Add Password';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        surfaceTintColor: Colors.transparent,
        title: Text(title),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: const LinearGradient(
                  colors: <Color>[AppColors.accentBlue, AppColors.accentPurple],
                ),
              ),
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  _saving ? 'Saving...' : 'Save',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              _LabeledField(
                label: 'Title',
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., GitHub, Gmail...',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Title is required.'
                      : null,
                ),
              ),
              _LabeledField(
                label: 'Website',
                child: TextFormField(
                  controller: _websiteController,
                  decoration: const InputDecoration(hintText: 'example.com'),
                  keyboardType: TextInputType.url,
                ),
              ),
              _LabeledField(
                label: 'Username',
                child: TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: 'username@email.com',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Username is required.'
                      : null,
                ),
              ),
              _LabeledField(
                labelWidget: Row(
                  children: <Widget>[
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _generatePassword,
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Generate'),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    hintText: 'Enter or generate password',
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Password is required.'
                      : null,
                ),
              ),
              _LabeledField(
                label: 'Notes (Optional)',
                child: TextFormField(
                  controller: _notesController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Add any additional notes...',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({this.label, this.labelWidget, required this.child});

  final String? label;
  final Widget? labelWidget;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          labelWidget ??
              Text(
                label ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
