import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/pages/settings/about_us_page.dart';
import 'package:dad_app/pages/settings/privacy_page.dart';
import 'package:dad_app/pages/sign_up_or_log_in_page.dart';
import 'package:dad_app/styles/google_maps_styles.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return InputErrors.emptyEmail;
    return InputErrors.emailChars.hasMatch(value.trim())
        ? null
        : InputErrors.emailError;
  }

  String? _newPasswordValidator(String? value) {
    final password = value ?? '';
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

  void _showError(SQLResponse? response, String fallback) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: BodyText(response?.errorMessage ?? fallback)),
    );
  }

  Future<void> _editProfile() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: User.user.name ?? '');
    final email = TextEditingController(
      text: User.user.email == 'NO-EMAIL' ? '' : User.user.email,
    );
    final currentPassword = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Header('Edit Profile'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  validator: (value) => value == null || value.trim().isEmpty
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
                  controller: currentPassword,
                  obscureText: true,
                  validator: (value) {
                    final original = User.user.email == 'NO-EMAIL'
                        ? ''
                        : (User.user.email ?? '').toLowerCase();
                    final changed = email.text.trim().toLowerCase() != original;
                    return changed && (value == null || value.isEmpty)
                        ? 'Enter your current password to change your email'
                        : null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Current password (for email changes)',
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
                name: name.text.trim(),
                email: email.text.trim().toLowerCase(),
              ).put(currentPassword: currentPassword.text);
              if (!dialogContext.mounted) return;
              if (response?.status == SQLResponseStatusTypes.success) {
                Navigator.pop(dialogContext);
                if (mounted) setState(() {});
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: BodyText(
                      response?.errorMessage ?? 'Could not update profile',
                    ),
                  ),
                );
              }
            },
            child: const ButtonText('Save'),
          ),
        ],
      ),
    );
    name.dispose();
    email.dispose();
    currentPassword.dispose();
  }

  Future<void> _changePassword() async {
    final formKey = GlobalKey<FormState>();
    final current = TextEditingController();
    final password = TextEditingController();
    final confirmation = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Header('Change Password'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: current,
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty
                      ? InputErrors.emptyPassword
                      : null,
                  decoration:
                      const InputDecoration(labelText: 'Current password'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  validator: _newPasswordValidator,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    helperText:
                        '10+ characters with uppercase, number, and symbol',
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmation,
                  obscureText: true,
                  validator: (value) => value != password.text
                      ? 'Passwords do not match'
                      : null,
                  decoration:
                      const InputDecoration(labelText: 'Confirm password'),
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
                name: User.user.name,
                email: User.user.email,
              ).put(
                newPassword: password.text,
                currentPassword: current.text,
              );
              if (!dialogContext.mounted) return;
              if (response?.status == SQLResponseStatusTypes.success) {
                Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: BodyText('Password changed')),
                  );
                }
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: BodyText(
                      response?.errorMessage ?? 'Could not change password',
                    ),
                  ),
                );
              }
            },
            child: const ButtonText('Change'),
          ),
        ],
      ),
    );
    current.dispose();
    password.dispose();
    confirmation.dispose();
  }

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Header('Log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const ButtonText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const ButtonText('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await User.user.logout();
    Get.offAll(() => const SignUpOrLogInPage());
  }

  Future<void> _deleteAccount() async {
    final formKey = GlobalKey<FormState>();
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Header('Delete Account'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: password,
            obscureText: true,
            validator: (value) => value == null || value.isEmpty
                ? InputErrors.emptyPassword
                : null,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const ButtonText('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const ButtonText('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final response = await User.user.drop(currentPassword: password.text);
      if (mounted && response?.status != SQLResponseStatusTypes.success) {
        _showError(response, 'Could not delete account');
      }
    }
    password.dispose();
  }

  void _saveMapSetting(int index, bool value) {
    final settings = preferences.getStringList('settings') ?? ['false', 'false'];
    while (settings.length < 2) {
      settings.add('false');
    }
    settings[index] = value.toString();
    preferences.setStringList('settings', settings);
  }

  Future<void> _setMapTheme(bool value) async {
    setState(() => darkModeMap = value);
    _saveMapSetting(1, value);
    if (googleMapsController.isCompleted) {
      final controller = await googleMapsController.future;
      await controller.setMapStyle(
        value ? googleMapsDarkMode : googleMapsLightMode,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(title: const Header('Profile')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: primaryColor(context),
                    child: const Icon(Icons.person, size: 58),
                  ),
                  const SizedBox(height: 16),
                  Header(User.user.name ?? 'User'),
                  const SizedBox(height: 4),
                  BodyText(
                    User.user.email == 'NO-EMAIL'
                        ? 'Email required before your next login'
                        : User.user.email ?? 'Email required',
                  ),
                  const SizedBox(height: 4),
                  BodyText(User.user.isAdmin ? 'Admin' : 'Observer'),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _editProfile,
                        icon: const Icon(Icons.edit_outlined),
                        label: const ButtonText('Edit profile'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(Icons.password_outlined),
                        label: const ButtonText('Change password'),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const SubHeader('Map'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const BodyText('Satellite transition'),
                    value: transitionMap,
                    onChanged: (value) {
                      setState(() => transitionMap = value);
                      _saveMapSetting(0, value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const BodyText('Dark map'),
                    value: darkModeMap,
                    onChanged: _setMapTheme,
                  ),
                  const Divider(height: 32),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.shield_outlined),
                    title: const BodyText('Privacy Policy'),
                    onTap: () => Get.to(() => const PrivacyPage()),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline),
                    title: const BodyText('About us'),
                    onTap: () => Get.to(() => const AboutUsPage()),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout),
                    title: const BodyText('Log out'),
                    onTap: _logOut,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text(
                      'Delete account',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
