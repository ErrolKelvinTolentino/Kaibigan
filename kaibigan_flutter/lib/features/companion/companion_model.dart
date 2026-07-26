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
      tag: 'Calm, steady, encouraging',
      description: 'Provides a grounded, thoughtful presence to help you unpack heavy thoughts gently.',
      primaryColor: AppColors.kaiPrimary,
      lightBgColor: AppColors.kaiLight,
      avatarIcon: '🌿',
      greetingTaglish: 'Kamusta ka ngayong araw? Nandito ako para makinig.',
      greetingFilipino: 'Kamusta ang iyong araw? Handa akong makinig sa iyo.',
      greetingEnglish: 'How are you feeling today? I am here to listen whenever you need.',
    ),
    MascotInfo(
      id: 'ann',
      name: 'Ann',
      tag: 'Warm, empathetic, nurturing',
      description: 'Offers deep emotional validation and gentle warmth like a trusted close friend.',
      primaryColor: AppColors.annPrimary,
      lightBgColor: AppColors.annLight,
      avatarIcon: '🌸',
      greetingTaglish: 'Medyo mabigat ba ang araw? Magpahinga ka muna rito sa piling ko.',
      greetingFilipino: 'Mabigat ba ang iyong pakiramdam? Dito ka muna magpahinga.',
      greetingEnglish: 'Feeling a bit overwhelmed? Rest your mind here with me.',
    ),
    MascotInfo(
      id: 'bee',
      name: 'Bee',
      tag: 'Friendly, expressive, inclusive',
      description: 'Expressive and uplifting space where every identity and emotion is celebrated.',
      primaryColor: AppColors.beePrimary,
      lightBgColor: AppColors.beeLight,
      avatarIcon: '🐝',
      greetingTaglish: 'Hey friend! Anong kwento mo ngayon? I-share mo lang kahit ano!',
      greetingFilipino: 'Magandang araw! Ano ang kwento ng iyong puso ngayon?',
      greetingEnglish: 'Hey there friend! What\'s on your mind today? Share whatever you feel!',
    ),
  ];

  static MascotInfo getById(String id) {
    return companions.firstWhere(
      (element) => element.id == id,
      orElse: () => companions[0],
    );
  }
}
