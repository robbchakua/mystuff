import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  List<User> users = [];
  bool loading = true;
  bool exporting = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final response = await User.listTeam();
    if (!mounted) return;
    setState(() {
      users = response?.users ?? [];
      loading = false;
    });
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return InputErrors.emptyEmail;
    return InputErrors.emailChars.hasMatch(value.trim())
        ? null
        : InputErrors.emailError;
  }

  String? _passwordValidator(String? value, {bool optional = false}) {
    final password = value ?? '';
    if (optional && password.isEmpty) return null;
    if (password.length < 10) return InputErrors.shortPassword;
    if (!InputErrors.uppercaseChars.hasMatch(password)) {
      return InputErrors.missingUppercase;
    }
    if (!InputErrors.numberChars.hasMatch(password)) {
      return InputErrors.missingNumber;
    }
    if (!InputErrors.specialChars.hasMatch(password)) {
      return InputErrors.missingSpecialChar;
    }
    return null;
  }

  Future<void> _createUser() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    String role = 'observer';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Header('Add Team Member'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? InputErrors.empty
                            : null,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    validator: _emailValidator,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: password,
                    obscureText: true,
                    validator: _passwordValidator,
                    decoration:
                        const InputDecoration(labelText: 'Temporary password'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: const [
                      DropdownMenuItem(
                        value: 'observer',
                        child: BodyText('Observer'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: BodyText('Admin'),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => role = value ?? 'observer'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const ButtonText('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final response = await User(
                  name: name.text.trim(),
                  email: email.text.trim().toLowerCase(),
                  password: password.text,
                  role: role,
                ).post();
                if (!dialogContext.mounted) return;
                if (response?.status == SQLResponseStatusTypes.success) {
                  Navigator.pop(dialogContext);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: BodyText(
                        response?.errorMessage ?? 'Could not add user',
                      ),
                    ),
                  );
                }
              },
              child: const ButtonText('Add'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    email.dispose();
    password.dispose();
    await _loadUsers();
  }

  Future<void> _editUser(User user) async {
    final formKey = GlobalKey<FormState>();
    final email = TextEditingController(
      text: user.email == 'NO-EMAIL' ? '' : user.email,
    );
    final resetPassword = TextEditingController();
    String role = user.role ?? 'observer';
    bool active = user.isActive ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Header(user.name ?? 'Team Member'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: email,
                    enabled: user.id != User.user.id,
                    validator: _emailValidator,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      helperText: user.id == User.user.id
                          ? 'Edit your own email from Profile.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: const [
                      DropdownMenuItem(
                        value: 'observer',
                        child: BodyText('Observer'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: BodyText('Admin'),
                      ),
                    ],
                    onChanged: user.id == User.user.id
                        ? null
                        : (value) =>
                            setDialogState(() => role = value ?? role),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const BodyText('Active'),
                    value: active,
                    onChanged: user.id == User.user.id
                        ? null
                        : (value) => setDialogState(() => active = value),
                  ),
                  TextFormField(
                    controller: resetPassword,
                    enabled: user.id != User.user.id,
                    obscureText: true,
                    validator: (value) =>
                        _passwordValidator(value, optional: true),
                    decoration: InputDecoration(
                      labelText: 'Reset password (optional)',
                      helperText: user.id == User.user.id
                          ? 'Change your own password from Profile.'
                          : 'The member’s other sessions will be signed out.',
                      helperMaxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const ButtonText('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final response = await User(
                  id: user.id,
                  name: user.name,
                  email: email.text.trim().toLowerCase(),
                  role: role,
                  isActive: active,
                ).put(
                  newPassword: resetPassword.text.isEmpty
                      ? null
                      : resetPassword.text,
                );
                if (!dialogContext.mounted) return;
                if (response?.status == SQLResponseStatusTypes.success) {
                  Navigator.pop(dialogContext);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: BodyText(
                        response?.errorMessage ?? 'Could not update user',
                      ),
                    ),
                  );
                }
              },
              child: const ButtonText('Save'),
            ),
          ],
        ),
      ),
    );
    email.dispose();
    resetPassword.dispose();
    await _loadUsers();
  }

  Future<void> _exportInventory() async {
    if (exporting) return;
    setState(() => exporting = true);
    final bytes = await User.exportInventory();
    if (!mounted) return;
    setState(() => exporting = false);
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: BodyText('Could not create the export')),
      );
      return;
    }
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Save MyStuff inventory',
      fileName: 'mystuff-inventory-$date.csv',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: bytes,
    );
    if (saved != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: BodyText('Inventory exported')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Header('Team'),
          actions: [
            IconButton(
              tooltip: 'Export inventory CSV',
              onPressed: exporting ? null : _exportInventory,
              icon: exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createUser,
          child: const Icon(Icons.person_add),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadUsers,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final email = user.email == 'NO-EMAIL'
                        ? 'Email required before next login'
                        : user.email ?? 'Email required';
                    return Card(
                      color: primaryColor(context),
                      child: ListTile(
                        leading: Icon(
                          user.role == 'admin'
                              ? Icons.admin_panel_settings
                              : Icons.person,
                        ),
                        title: BodyText(user.name ?? ''),
                        subtitle: Text(
                          '$email • ${user.role}'
                          '${user.isActive == false ? ' • disabled' : ''}',
                        ),
                        onTap: () => _editUser(user),
                      ),
                    );
                  },
                ),
              ),
      );
}
