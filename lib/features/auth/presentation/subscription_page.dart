import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String _selectedPlan = 'monthly';

  void _proceedToPayment() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Selected Plan: $_selectedPlan")));
    context.go('/home'); // Replace with payment page later
  }

  Widget _buildPlanOption({
    required String plan,
    required String price,
    required String subtitle,
  }) {
    final bool isSelected = _selectedPlan == plan;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedPlan = plan),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.blue : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.blue)
            else
              const Icon(Icons.radio_button_off, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Subscription Plans")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select a Plan",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            _buildPlanOption(
              plan: 'monthly',
              price: "\$20 / Month",
              subtitle: "Billed monthly, cancel anytime.",
            ),
            _buildPlanOption(
              plan: '3-month',
              price: "\$55 / 3 Months",
              subtitle: "Save \$5 compared to monthly.",
            ),
            _buildPlanOption(
              plan: '6-month',
              price: "\$100 / 6 Months",
              subtitle: "Save \$20 compared to monthly.",
            ),
            _buildPlanOption(
              plan: '1-year',
              price: "\$180 / Year",
              subtitle: "Best deal: Save \$60 (25% off).",
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _proceedToPayment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Continue to Payment",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
