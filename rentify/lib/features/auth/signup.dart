import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _agree = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Image.asset(
                      "assets/images/logoo.png",
                      width: 100,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'by creating a free account.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),

                  buildTextField(
                    'Full name',
                    Icons.person_outline,
                    _nameController,
                    validator: (value) =>
                        value!.isEmpty ? 'Full name is required' : null,
                  ),
                  const SizedBox(height: 12),

                  buildTextField(
                    'Valid email',
                    Icons.email_outlined,
                    _emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      final emailRegex = RegExp(r'^.+@.+\..+$');
                      return emailRegex.hasMatch(value)
                          ? null
                          : 'Enter a valid email address';
                    },
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }

                      final hasUppercase = value.contains(RegExp(r'[A-Z]'));
                      final hasLowercase = value.contains(RegExp(r'[a-z]'));
                      final hasDigit = value.contains(RegExp(r'\d'));
                      final hasSpecial = value.contains(RegExp(r'[!@#\$&*~]'));
                      final hasMinLength = value.length >= 8;

                      if (!hasMinLength) {
                        return 'At least 8 characters required';
                      }
                      if (!hasUppercase) {
                        return 'Include at least one uppercase letter';
                      }
                      if (!hasLowercase) {
                        return 'Include at least one lowercase letter';
                      }
                      if (!hasDigit) {
                        return 'Include at least one number';
                      }
                      if (!hasSpecial) {
                        return 'Include at least one special character';
                      }

                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Strong Password',
                      hintStyle: const TextStyle(color: Colors.black38),
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.deepOrangeAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Checkbox(
                        value: _agree,
                        onChanged: (value) =>
                            setState(() => _agree = value ?? false),
                      ),
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            text: 'By checking the box you agree to our ',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                            children: [
                              TextSpan(
                                text: 'Terms ',
                                style: const TextStyle(
                                  color: Colors.deepOrangeAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _showTermsDialog(context),
                              ),
                              const TextSpan(text: 'and '),
                              TextSpan(
                                text: 'Conditions.',
                                style: const TextStyle(
                                  color: Colors.deepOrangeAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _showTermsDialog(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrangeAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          if (!_agree) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please accept the Terms and Conditions to continue.',
                                ),
                              ),
                            );
                            return;
                          }

                          final authService = AuthService();
                          await authService.signUp(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                            firstName:
                                _nameController.text.trim().split(' ').first,
                            lastName: _nameController.text
                                        .trim()
                                        .split(' ')
                                        .length >
                                    1
                                ? _nameController.text.trim().split(' ').last
                                : '',
                            context: context,
                          );
                        }
                      },
                      child: const Text(
                        'Next  >',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already a member? ',
                        style: TextStyle(color: Colors.black54),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: Colors.deepOrangeAccent,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildTextField(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Terms and Conditions",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            """By creating an account, you agree to the following:

1. You are responsible for the accuracy of the information you provide.
2. Your data will be used in accordance with our privacy policy.
3. You agree not to misuse the platform or engage in fraudulent activity.
4. The company reserves the right to suspend or terminate accounts that violate these terms.
5. Additional terms may apply for specific services.

These Terms and Conditions are subject to change at any time without prior notice.""",
            style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(
                color: Colors.deepOrangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
