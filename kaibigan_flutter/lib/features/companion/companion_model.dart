import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MascotInfo {
  final String id;
  final String name;
  final String tag;
  final String description;
  final Color primaryColor;
  final Color lightBgColor;
  final String avatarIcon;
  final String greetingTaglish;
  final String greetingFilipino;
  final String greetingEnglish;

  const MascotInfo({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.primaryColor,
    required this.lightBgColor,
    required this.avatarIcon,
    required this.greetingTaglish,
    required this.greetingFilipino,
    required this.greetingEnglish,
  });

  static const List<MascotInfo> companions = [
    MascotInfo(
      id: 'kai',
      name: 'Kai',
      tag: 'Male Bee Companion • Steady & Grounded',
      description: 'Dressed in honey-gold and warm slate bee attire. Provides a calming, encouraging presence to help you organize thoughts.',
      primaryColor: AppColors.kaiPrimary,
      lightBgColor: AppColors.kaiLight,
      avatarIcon: 'Kai',
      greetingTaglish: 'Kamusta ka ngayong araw? Nandito ako para samahan ka mag-reflect.',
      greetingFilipino: 'Magandang araw sa iyo. Handa akong makinig at samahan ka.',
      greetingEnglish: 'How are you feeling today? Take your time, I am right here with you.',
    ),
    MascotInfo(
      id: 'ann',
      name: 'Ann',
      tag: 'Female Bee Companion • Warm & Empathetic',
      description: 'Dressed in blossom-peach and honey bee attire. Offers gentle emotional care and validation like a loving close friend.',
      primaryColor: AppColors.annPrimary,
      lightBgColor: AppColors.annLight,
      avatarIcon: 'Ann',
      greetingTaglish: 'Medyo mabigat ba ang pakiramdam mo? Magpahinga ka muna rito.',
      greetingFilipino: 'Mabigat ba ang iyong puso? Dito ka muna magpahinga at mag-breathe.',
      greetingEnglish: 'Feeling a bit tired or overwhelmed? Rest your mind here with me.',
    ),
  ];

  IconData get materialIcon {
    if (id == 'ann') return Icons.favorite_rounded;
    return Icons.spa_rounded;
  }

  static MascotInfo getById(String id) {
    return companions.firstWhere(
      (element) => element.id == id,
      orElse: () => companions[0],
    );
  }

  static MascotInfo getMascot(String id) => getById(id);
}
