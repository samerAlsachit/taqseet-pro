import 'package:flutter/material.dart';
import '../../../core/config/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _plans = [
    {'name': 'شهري', 'price': '15,000', 'period': '30 يوم', 'customers': '200', 'employees': '2'},
    {'name': 'سنوي', 'price': '130,000', 'period': '365 يوم', 'customers': '1000', 'employees': '5', 'popular': true},
    {'name': '3 سنوات', 'price': '350,000', 'period': '1095 يوم', 'customers': 'غير محدود', 'employees': '10'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A192F), Color(0xFF0066FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.anchor, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text('مرساة', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Tajawal')),
                  const SizedBox(height: 8),
                  Text(AppConstants.appDescription, style: const TextStyle(fontSize: 14, color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  _buildActionButton(context, 'تسجيل الدخول', '/login', isPrimary: true),
                  const SizedBox(height: 12),
                  _buildActionButton(context, 'تفعيل كود', '/activate', icon: Icons.key),
                  const SizedBox(height: 12),
                  _buildActionButton(context, 'تجربة مجانية ${AppConstants.trialDays} يوم', '/register', icon: Icons.card_giftcard),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('خطط الأسعار', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                  const SizedBox(height: 8),
                  const Text('اختر الخطة المناسبة لمتجرك', style: TextStyle(color: AppColors.textSecondaryLight)),
                  const SizedBox(height: 24),
                  ..._plans.map((plan) => _buildPlanCard(context, plan)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text, String route, {bool isPrimary = false, IconData? icon}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, route),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.white : Colors.transparent,
          foregroundColor: isPrimary ? AppColors.navy : Colors.white,
          side: isPrimary ? null : const BorderSide(color: Colors.white),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(text),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Map plan) {
    final popular = plan['popular'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: popular ? AppColors.electric : AppColors.borderLight, width: popular ? 2 : 1),
        boxShadow: popular ? [BoxShadow(color: AppColors.electric.withValues(alpha: 0.2), blurRadius: 12)] : null,
      ),
      child: Stack(
        children: [
          if (popular)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.electric,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Text('الأكثر طلباً', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, popular ? 32 : 20, 20, 20),
            child: Column(
              children: [
                Text(plan['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                const SizedBox(height: 8),
                Text('${plan['price']} IQD', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.electric, fontFamily: 'Tajawal')),
                Text(plan['period'], style: const TextStyle(color: AppColors.textSecondaryLight)),
                const SizedBox(height: 12),
                _buildFeature('حتى ${plan['customers']} عميل'),
                _buildFeature('حتى ${plan['employees']} موظف'),
                _buildFeature('دعم فني'),
                _buildFeature('تحديثات مجانية'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text('ابدأ الآن'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        const Icon(Icons.check, size: 16, color: AppColors.success),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontFamily: 'Tajawal')),
      ],
    ),
  );
}
