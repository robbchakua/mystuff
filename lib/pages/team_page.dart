import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:flutter/material.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  List<User> users = [];
  bool loading = true;

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

  Future<void> _createUser() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final username = TextEditingController();
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
                    validator: _required,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextFormField(
                    controller: username,
                    validator: _required,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(labelText: 'Email (optional)'),
                  ),
                  TextFormField(
                    controller: password,
                    obscureText: true,
                    validator: (value) => value == null || value.length < 10
                        ? InputErrors.shortPassword
                        : null,
                    decoration:
                        const InputDecoration(labelText: 'Temporary password'),
                  ),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: const [
                      DropdownMenuItem(
                          value: 'observer', child: BodyText('Observer')),
                      DropdownMenuItem(
                          value: 'admin', child: BodyText('Admin')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => role = value ?? 'observer'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const ButtonText('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final response = await User(
                  userid: username.text.trim(),
                  name: name.text.trim(),
                  email: email.text.trim().isEmpty
                      ? 'NO-EMAIL'
                      : email.text.trim(),
                  password: password.text,
                  role: role,
                ).post();
                if (response?.status == SQLResponseStatusTypes.success &&
                    dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                } else if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                    content: BodyText(
                        response?.errorMessage ?? 'Could not add user'),
                  ));
                }
              },
              child: const ButtonText('Add'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    username.dispose();
    email.dispose();
    password.dispose();
    await _loadUsers();
  }

  Future<void> _editUser(User user) async {
    String role = user.role ?? 'observer';
    bool active = user.isActive ?? true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Header(user.name ?? 'Team Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Level'),
                items: const [
                  DropdownMenuItem(
                      value: 'observer', child: BodyText('Observer')),
                  DropdownMenuItem(value: 'admin', child: BodyText('Admin')),
                ],
                onChanged: user.id == User.user.id
                    ? null
                    : (value) => setDialogState(() => role = value ?? role),
              ),
              SwitchListTile(
                title: const BodyText('Active'),
                value: active,
                onChanged: user.id == User.user.id
                    ? null
                    : (value) => setDialogState(() => active = value),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const ButtonText('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final response = await User(
                  id: user.id,
                  name: user.name,
                  email: user.email,
                  role: role,
                  isActive: active,
                ).put();
                if (response?.status == SQLResponseStatusTypes.success &&
                    dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                } else if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(
                    content: BodyText(
                        response?.errorMessage ?? 'Could not update user'),
                  ));
                }
              },
              child: const ButtonText('Save'),
            ),
          ],
        ),
      ),
    );
    await _loadUsers();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? InputErrors.empty : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(title: const Header('Team')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createUser,
        child: const Icon(Icons.person_add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  color: primaryColor(context),
                  child: ListTile(
                    leading: Icon(user.role == 'admin'
                        ? Icons.admin_panel_settings
                        : Icons.person),
                    title: BodyText(user.name ?? ''),
                    subtitle: BodyText(
                      '${user.userid} • ${user.role}'
                      '${user.isActive == false ? ' • disabled' : ''}',
                    ),
                    onTap: () => _editUser(user),
                  ),
                );
              },
            ),
    );
  }
}
