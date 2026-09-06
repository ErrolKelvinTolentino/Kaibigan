import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/kaibigan_tokens.dart';
import '../../../core/utils/language_helper.dart';
import '../../../core/widgets/kaibigan_surface.dart';

class FriendSupportSafetySheet extends StatelessWidget {
  const FriendSupportSafetySheet({super.key, required this.language});

  final String language;

  static Future<void> show(BuildContext context, {required String language}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FriendSupportSafetySheet(language: language),
    );
  }

  Future<void> _call(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LanguageHelper.pick(
                language,
                english: 'Unable to start call to $urlString',
                filipino: 'Hindi masimulan ang tawag sa $urlString',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: KaibiganSurface(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: palette.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.health_and_safety_rounded,
                        color: palette.danger,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LanguageHelper.pick(
                              language,
                              english: 'Need Immediate Help?',
                              filipino: 'Kailangan ng Tulong?',
                            ),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            LanguageHelper.pick(
                              language,
                              english: 'Philippine Crisis Support & Hotlines',
                              filipino: 'Suporta at Hotline sa Pilipinas',
                            ),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: palette.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: LanguageHelper.pick(
                        language,
                        english: 'Close',
                        filipino: 'Isara',
                      ),
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.accentSubtle.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: palette.accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: palette.accentStrong,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          LanguageHelper.pick(
                            language,
                            english:
                                'You don\'t have to handle a crisis alone. If someone may be in immediate danger, involve a trusted person or appropriate emergency/crisis support.',
                            filipino:
                                'Hindi mo kailangang harapin ang isang crisis nang mag-isa. Kung maaaring nasa agarang panganib ang isang tao, magsabi sa isang taong pinagkakatiwalaan o humingi ng naaangkop na emergency/crisis support.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: palette.textPrimary,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  LanguageHelper.pick(
                    language,
                    english: 'Emergency Contacts',
                    filipino: 'Mga Emergency Contact',
                  ),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                _ContactItem(
                  icon: Icons.emergency_rounded,
                  title: LanguageHelper.pick(
                    language,
                    english: 'Emergency (National Hotline)',
                    filipino: 'Emergency (Pambansang Hotline)',
                  ),
                  detail: LanguageHelper.pick(
                    language,
                    english: 'Unified nationwide emergency hotline',
                    filipino: 'Pambansang emergency hotline',
                  ),
                  number: '911',
                  color: palette.danger,
                  onTap: () => _call(context, 'tel:911'),
                ),
                const SizedBox(height: 8),
                _ContactItem(
                  icon: Icons.support_agent_rounded,
                  title: LanguageHelper.pick(
                    language,
                    english: 'NCMH Crisis Hotline',
                    filipino: 'NCMH Crisis Hotline',
                  ),
                  detail: LanguageHelper.pick(
                    language,
                    english: 'National Center for Mental Health',
                    filipino: 'National Center for Mental Health',
                  ),
                  number: '1553',
                  color: palette.accentStrong,
                  onTap: () => _call(context, 'tel:1553'),
                ),
                const SizedBox(height: 8),
                _ContactItem(
                  icon: Icons.phone_android_rounded,
                  title: LanguageHelper.pick(
                    language,
                    english: 'NCMH Mobile Line',
                    filipino: 'NCMH Mobile Line',
                  ),
                  detail: LanguageHelper.pick(
                    language,
                    english: 'Toll-free mobile hotline backup',
                    filipino: 'Backup mobile hotline',
                  ),
                  number: '0917 899 8727',
                  color: palette.accent,
                  onTap: () => _call(context, 'tel:+639178998727'),
                ),
                const SizedBox(height: 14),
                Text(
                  LanguageHelper.pick(
                    language,
                    english:
                        'Hotline availability and network access can change. If danger is imminent and phones do not connect, proceed immediately to the nearest hospital emergency room.',
                    filipino:
                        'Maaaring magbago ang availability ng linya. Kung may agarang panganib at hindi makontak, magtungo agad sa pinakamalapit na emergency room.',
                  ),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  const _ContactItem({
    required this.icon,
    required this.title,
    required this.detail,
    required this.number,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String number;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.kaibigan;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette.surfaceSubtle,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.call_rounded, size: 15, color: color),
                    const SizedBox(width: 5),
                    Text(
                      number,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
