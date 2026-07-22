import 'dart:math';

import 'package:dad_app/models/response_model.dart';
import 'package:dad_app/models/user_model.dart';
import 'package:dad_app/pages/home.dart';
import 'package:dad_app/styles/themes.dart';
import 'package:dad_app/utils/constants.dart';
import 'package:dad_app/utils/utils.dart';
import 'package:dad_app/widgets/text.dart';
import 'package:flutter/material.dart' hide Title;
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SignUpOrLogInPage extends StatefulWidget {
  const SignUpOrLogInPage({super.key});

  @override
  State<SignUpOrLogInPage> createState() => _SignUpOrLogInPageState();
}

class _SignUpOrLogInPageState extends State<SignUpOrLogInPage> {
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _generatedUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signUpPasswordController = TextEditingController();

  bool _showSignUp = true;
  bool _showPassword = false;
  bool _acceptedPrivacyPolicy = false;
  bool _privacyPolicyError = false;
  bool _processing = false;
  int _randomSuffix = Random().nextInt(1000);

  @override
  void dispose() {
    _nameController.dispose();
    _generatedUsernameController.dispose();
    _loginPasswordController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  String _createUserId(String name) {
    final normalized = name
        .toLowerCase()
        .removeAllWhitespace
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    return normalized.isEmpty ? 'user' : normalized;
  }

  void _updateGeneratedUsername() {
    final name = _nameController.text.trim();
    _generatedUsernameController.text =
        name.isEmpty ? '' : '${_createUserId(name)}$_randomSuffix';
  }

  void _createNewRandomSuffix() {
    setState(() {
      _randomSuffix = Random().nextInt(1000);
      _updateGeneratedUsername();
    });
  }

  void _selectPage(bool showSignUp) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _showSignUp = showSignUp;
      userNotFound = false;
      incorrectPassword = false;
    });
  }

  Future<bool> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Title('Alert'),
        content: const Header('Do you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const ButtonText('Yes'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const ButtonText('No'),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
    }
    return false;
  }

  Future<void> _signUp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_signUpFormKey.currentState!.validate()) return;
    if (!_acceptedPrivacyPolicy) {
      setState(() => _privacyPolicyError = true);
      return;
    }

    setState(() {
      _privacyPolicyError = false;
      _processing = true;
    });
    final response = await User(
      userid: _generatedUsernameController.text,
      name: _nameController.text.trim(),
      email: 'NO-EMAIL',
      password: _signUpPasswordController.text,
      joinDate: timeNow,
    ).post(false);
    if (!mounted) return;

    setState(() => _processing = false);
    if (response?.status == SQLResponseStatusTypes.success) {
      Get.offAll(() => const Home());
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: BodyText(response?.errorMessage ?? 'Could not create account'),
      ),
    );
  }

  Future<void> _logIn() async {
    FocusManager.instance.primaryFocus?.unfocus();
    userNotFound = false;
    incorrectPassword = false;
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _processing = true);
    final authenticated = await User(
      name: '',
      userid: usernameController.text.trim(),
      email: usernameController.text.trim(),
      password: _loginPasswordController.text,
    ).validate();
    if (!mounted) return;

    setState(() => _processing = false);
    if (authenticated) {
      Get.offAll(() => const Home());
    } else {
      _loginFormKey.currentState!.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    max(24.0, keyboardHeight + 24.0),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: max(
                        0.0,
                        constraints.maxHeight - keyboardHeight - 48,
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _pageSelector(),
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.fromLTRB(20, 24, 20, 20),
                              decoration: BoxDecoration(
                                color: primaryColor(context),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(30),
                                ),
                              ),
                              child:
                                  _showSignUp ? _signUpForm() : _loginForm(),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: VersionText(AppDetails.version),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_processing)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xCC000000),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: inverseColor(context),
                          ),
                          const SizedBox(height: 16),
                          SubHeader(
                            _showSignUp
                                ? 'Creating your account...'
                                : 'Logging you in...',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageSelector() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: primaryColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Row(
          children: [
            Expanded(child: _pageButton('Sign Up', true)),
            Expanded(child: _pageButton('Log In', false)),
          ],
        ),
      );

  Widget _pageButton(String label, bool signUp) {
    final selected = _showSignUp == signUp;
    return Semantics(
      selected: selected,
      button: true,
      child: TextButton(
        onPressed: _processing ? null : () => _selectPage(signUp),
        style: TextButton.styleFrom(
          backgroundColor: selected ? backgroundColor : Colors.transparent,
          foregroundColor: inverseColor(context),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: selected ? 20 : 16,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _signUpForm() => AutofillGroup(
        child: Form(
          key: _signUpFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final nameField = _nameField();
                  final usernameField = _generatedUsernameField();
                  if (constraints.maxWidth < 480) {
                    return Column(
                      children: [
                        nameField,
                        const SizedBox(height: 16),
                        usernameField,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: nameField),
                      const SizedBox(width: 16),
                      Expanded(child: usernameField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _passwordField(
                controller: _signUpPasswordController,
                newPassword: true,
                onSubmitted: (_) => _signUp(),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _acceptedPrivacyPolicy,
                onChanged: _processing
                    ? null
                    : (value) => setState(() {
                          _acceptedPrivacyPolicy = value ?? false;
                          if (_acceptedPrivacyPolicy) {
                            _privacyPolicyError = false;
                          }
                        }),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.blue,
                title: Text(
                  _privacyPolicyError
                      ? 'Please accept the privacy policy.'
                      : 'I agree to the MyStuff Privacy Policy.',
                  style: TextStyle(
                    color: _privacyPolicyError
                        ? Colors.red
                        : inverseColor(context),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _submitButton('SIGN UP', _signUp),
            ],
          ),
        ),
      );

  Widget _loginForm() => AutofillGroup(
        child: Form(
          key: _loginFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: usernameController,
                enabled: !_processing,
                autofillHints: const [AutofillHints.username],
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name/Email cannot be empty';
                  }
                  if (userNotFound) return 'Name/Email does not exist';
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Name/Email',
                  suffixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              _passwordField(
                controller: _loginPasswordController,
                newPassword: false,
                onSubmitted: (_) => _logIn(),
              ),
              const SizedBox(height: 12),
              Text(
                'Password recovery is coming later.',
                style: TextStyle(color: middleGrey(context)),
              ),
              const SizedBox(height: 24),
              _submitButton('LOG IN', _logIn),
            ],
          ),
        ),
      );

  Widget _nameField() => TextFormField(
        controller: _nameController,
        enabled: !_processing,
        autofillHints: const [AutofillHints.name],
        keyboardType: TextInputType.name,
        textInputAction: TextInputAction.next,
        onChanged: (_) => setState(_updateGeneratedUsername),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return InputErrors.emptyUsername;
          }
          if (value.trim().length > 20) return InputErrors.longName;
          return null;
        },
        decoration: const InputDecoration(
          labelText: 'Name',
          suffixIcon: Icon(Icons.person),
        ),
      );

  Widget _generatedUsernameField() => TextFormField(
        controller: _generatedUsernameController,
        readOnly: true,
        enableInteractiveSelection: true,
        decoration: InputDecoration(
          labelText: 'Username',
          hintText: 'Generated from your name',
          suffixIcon: IconButton(
            tooltip: 'Generate another username',
            onPressed: _processing ? null : _createNewRandomSuffix,
            icon: const Icon(Icons.refresh_outlined),
          ),
        ),
      );

  Widget _passwordField({
    required TextEditingController controller,
    required bool newPassword,
    required ValueChanged<String> onSubmitted,
  }) =>
      TextFormField(
        controller: controller,
        enabled: !_processing,
        autofillHints: [
          newPassword ? AutofillHints.newPassword : AutofillHints.password,
        ],
        obscureText: !_showPassword,
        obscuringCharacter: '•',
        textInputAction: TextInputAction.done,
        onFieldSubmitted: onSubmitted,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return InputErrors.emptyPassword;
          }
          if (!newPassword && incorrectPassword) return 'Incorrect password';
          if (!newPassword) return null;
          if (!InputErrors.uppercaseChars.hasMatch(value)) {
            return InputErrors.missingUppercase;
          }
          if (!InputErrors.numberChars.hasMatch(value)) {
            return InputErrors.missingNumber;
          }
          if (!InputErrors.specialChars.hasMatch(value)) {
            return InputErrors.missingSpecialChar;
          }
          if (value.length < 10) return InputErrors.shortPassword;
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Password',
          helperText: newPassword
              ? '10+ characters with uppercase, number, and symbol'
              : null,
          helperMaxLines: 2,
          suffixIcon: IconButton(
            tooltip: _showPassword ? 'Hide password' : 'Show password',
            onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: Icon(
              _showPassword ? Icons.visibility : Icons.visibility_off,
            ),
          ),
        ),
      );

  Widget _submitButton(String label, Future<void> Function() onPressed) =>
      OutlinedButton(
        onPressed: _processing ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: inverseColor(context),
          side: const BorderSide(color: Colors.white),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      );
}
