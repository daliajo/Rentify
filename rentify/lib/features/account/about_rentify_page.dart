import 'package:flutter/material.dart';

const kOrange = Color(0xFFFF7A00);

class AboutRentifyPage extends StatelessWidget {
  const AboutRentifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'About Rentify',
          style: TextStyle(
            color: kOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: kOrange.withOpacity(0.12),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(
                        'assets/images/logoo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'About Rentify',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Rentify is a peer-to-peer rental platform that allows users '
                    'to rent and lend items easily and securely.\n\n'
                    'The platform promotes sustainability by encouraging shared '
                    'use of items, reducing unnecessary purchases, and providing '
                    'affordable access to tools, equipment, and everyday products.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Terms & Privacy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _policyTile(
                    title: 'Platform Role',
                    text:
                        'Rentify acts as an intermediary platform between renters and item owners.',
                  ),
                  _policyTile(
                    title: 'Rental Agreements',
                    text:
                        'All rental agreements are made directly between users.',
                  ),
                  _policyTile(
                    title: 'Security Deposits',
                    text:
                        'Security deposits may be required and are refundable after item inspection.',
                  ),
                  _policyTile(
                    title: 'User Responsibility',
                    text:
                        'Users are responsible for maintaining accurate account information.',
                  ),
                  _policyTile(
                    title: 'Privacy & Data',
                    text:
                        'Personal data is stored securely and is not shared with third parties.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

      
            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.black38, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  static Widget _policyTile({
    required String title,
    required String text,
  }) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Text(
          text,
          style: const TextStyle(color: Colors.black54, height: 1.5),
        ),
      ],
    );
  }
}
