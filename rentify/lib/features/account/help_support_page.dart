import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.deepOrangeAccent;

    final faqs = [
      {
        'question': 'Why can’t I add an item to the cart?',
        'answer':
            'The item may be out of stock, already rented, or listed by you.',
      },
      {
        'question': 'Do I need to pay a security deposit?',
        'answer':
            'Some items require a refundable security deposit. The amount is shown before checkout.',
      },
      {
        'question': 'How do I contact the item owner?',
        'answer':
            'Open the item page and tap on “Contact Seller” to start a chat.',
      },
      {
        'question': 'What happens after I place an order?',
        'answer':
            'You will pay in cash when you receive the item. The owner will prepare it for pickup or delivery.',
      },
      {
        'question': 'How do I edit my account information?',
        'answer': 'Go to the Account page and tap on “Edit Profile”.',
      },
      {
        'question': 'Can I pay using Visa, credit cards, or CliQ?',
        'answer':
            'At the moment, Rentify supports cash payment on delivery only. Online payments (Visa, credit cards, CliQ, etc.) are still under development. You may agree on a different payment method directly with the item owner through chat.',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
    
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Center(
                child: Image.asset(
                  "assets/images/logoo.png",
                  width: 55,
                ),
              ),
            ),

          
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.black87, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Help & Support",
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            
            ...faqs.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ExpansionTile(
                    iconColor: primaryColor,
                    collapsedIconColor: Colors.grey,
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      item['question']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    children: [
                      Text(
                        item['answer']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
