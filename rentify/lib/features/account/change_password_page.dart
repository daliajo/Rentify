import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _minLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    _newController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final text = _newController.text;
    setState(() {
      _minLength = text.length >= 8;
      _hasUppercase = text.contains(RegExp(r'[A-Z]'));
      _hasNumber = text.contains(RegExp(r'[0-9]'));
      _hasSpecial = text.contains(RegExp(r'[!@#%^&*(),.?":{}|<>_\-@$]'));
    });
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (!(_minLength && _hasUppercase && _hasNumber && _hasSpecial)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please meet all password requirements."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: _currentController.text.trim(),
      );

      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(_newController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password changed successfully!"),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred";
      if (e.code == 'wrong-password') {
        message = "The current password you entered is incorrect.";
      } else if (e.code == 'weak-password') {
        message = "The new password is too weak.";
      } else if (e.code == 'requires-recent-login') {
        message = "Please log in again before changing your password.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Change Password",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 25),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Update your password securely",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              _buildPasswordField(
                label: "Current Password",
                controller: _currentController,
                obscureText: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              const SizedBox(height: 15),
              _buildPasswordField(
                label: "New Password",
                controller: _newController,
                obscureText: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 8),
              _buildPasswordConstraints(),
              const SizedBox(height: 15),
              _buildPasswordField(
                label: "Confirm Password",
                controller: _confirmController,
                obscureText: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value!.isEmpty) return "Confirm your new password";
                  if (value != _newController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
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


  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator ??
            (value) {
              if (value!.isEmpty) return "Please enter $label";
              if (label == "New Password" && value.length < 8) {
                return "Password must be at least 8 characters";
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              obscureText
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.orange,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordConstraints() {
    final constraints = [
      _PasswordRule("At least 8 characters", _minLength),
      _PasswordRule("At least 1 uppercase letter", _hasUppercase),
      _PasswordRule("At least 1 number", _hasNumber),
      _PasswordRule("At least 1 special character", _hasSpecial),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Password must include:",
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ...constraints.mapIndexed((_, rule) => _buildConstraintItem(rule)),
      ],
    );
  }

  Widget _buildConstraintItem(_PasswordRule rule) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            rule.isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: rule.isMet ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            rule.text,
            style: TextStyle(
              color: rule.isMet ? Colors.green.shade800 : Colors.black54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordRule {
  final String text;
  final bool isMet;
  _PasswordRule(this.text, this.isMet);
}
