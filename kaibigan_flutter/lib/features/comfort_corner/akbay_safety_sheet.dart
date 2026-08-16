import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

class AkbaySafetySheet extends StatelessWidget {
  const AkbaySafetySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AkbaySafetySheet(),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header with Shield Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akbay Safety Net',
                      style: AppTypography.titleLarge(context, isDark: isDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nandito kami para sa iyo. Hindi ka nag-iisa.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Informational Alert Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sageGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.sageGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.sageGreen, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'If you or someone you know is feeling overwhelmed or needs urgent emotional support, free 24/7 help is available right now.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Hotline Items
          Text('24/7 Philippines Mental Health Warm-Lines:', style: AppTypography.titleSmall(context, isDark: isDark)),
          const SizedBox(height: 12),

          _buildHotlineCard(
            context,
            title: 'National Center for Mental Health (NCMH)',
            numberDisplay: '1553 (Toll-Free) / 0917-899-8727',
            dialNumber: '1553',
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          _buildHotlineCard(
            context,
            title: 'Hopeline Philippines',
            numberDisplay: '0917-558-4673 / (02) 8804-4673',
            dialNumber: '09175584673',
            isDark: isDark,
          ),
          const SizedBox(height: 10),

          _buildHotlineCard(
            context,
            title: 'In Touch Community Crisis Line',
            numberDisplay: '0917-800-1123 / (02) 8893-7603',
            dialNumber: '09178001123',
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          // Close Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkCardBorder : Colors.grey.shade300,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Close',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotlineCard(
    BuildContext context, {
    required String title,
    required String numberDisplay,
    required String dialNumber,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBorder : const Color(0xFFF6F4ED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(numberDisplay, style: const TextStyle(fontSize: 12, color: AppColors.sageGreen, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _makePhoneCall(dialNumber),
            icon: const Icon(Icons.phone, color: AppColors.sageGreen),
            tooltip: 'Call Hotline',
          ),
        ],
      ),
    );
  }
}
