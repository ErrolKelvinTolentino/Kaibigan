import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/language_helper.dart';

class FavoriteActivityData {
  const FavoriteActivityData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.assetPath,
    required this.onTap,
    this.placeholderIcon,
    this.placeholderColor,
    this.usageCount = 0,
  });

  final String id;
  final String title;
  final String subtitle;
  final Color accent;
  final String assetPath;
  final VoidCallback onTap;
  final IconData? placeholderIcon;
  final Color? placeholderColor;
  final int usageCount;
}

class HomeFavoritesCarousel extends StatelessWidget {
  const HomeFavoritesCarousel({
    super.key,
    required this.favorites,
    required this.isDark,
    required this.language,
  });

  final List<FavoriteActivityData> favorites;
  final bool isDark;
  final String language;

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) {
      return const SizedBox.shrink();
    }

    final foreground =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return SizedBox(
      key: const ValueKey('home-favorites-carousel'),
      height: 194,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final item = favorites[index];
          final rankLabel = switch (index) {
            0 => LanguageHelper.pick(
                language,
                english: '★ #1 Most Used',
                filipino: '★ #1 Pinakaginagamit',
              ),
            1 => LanguageHelper.pick(
                language,
                english: '★ #2 Favorite',
                filipino: '★ #2 Paborito',
              ),
            _ => LanguageHelper.pick(
                language,
                english: '★ #3 Frequent',
                filipino: '★ #3 Madalas',
              ),
          };

          return Semantics(
            button: true,
            label: '${item.title}. ${item.subtitle}',
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(23),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  key: ValueKey('favorite-activity-card-$index'),
                  onTap: item.onTap,
                  child: Ink(
                    width: 148,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                Color.alphaBlend(
                                  item.accent.withValues(alpha: 0.16),
                                  AppColors.darkCard,
                                ),
                                AppColors.darkCard,
                              ]
                            : [
                                Color.alphaBlend(
                                  item.accent.withValues(alpha: 0.18),
                                  Colors.white,
                                ),
                                Colors.white,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(
                        color: item.accent.withValues(alpha: 0.34),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.accent.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Artwork Image with Rounded Corners and Floating Rank Badge
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(22),
                            topRight: Radius.circular(22),
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                          child: Container(
                            width: double.infinity,
                            height: 121,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        Color.alphaBlend(
                                          item.accent.withValues(alpha: 0.24),
                                          AppColors.darkHoneySurface,
                                        ),
                                        AppColors.darkCard,
                                      ]
                                    : [
                                        Color.alphaBlend(
                                          item.accent.withValues(alpha: 0.28),
                                          AppColors.honeyLight,
                                        ),
                                        AppColors.honeyLight,
                                      ],
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  item.assetPath,
                                  width: double.infinity,
                                  height: 121,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                  isAntiAlias: true,
                                  errorBuilder: (_, __, ___) => Icon(
                                    item.placeholderIcon ?? Icons.spa_rounded,
                                    size: 40,
                                    color: item.placeholderColor ?? item.accent,
                                  ),
                                ),
                                // Floating Rank Badge on top of artwork
                                Positioned(
                                  top: 7,
                                  left: 7,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                              ? const Color(0xFF1C1D18)
                                              : Colors.white)
                                          .withValues(alpha: 0.92),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: item.accent
                                            .withValues(alpha: 0.45),
                                        width: 0.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.25 : 0.10,
                                          ),
                                          blurRadius: 5,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          rankLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isDark
                                                ? AppColors.honeyGold
                                                : AppColors.honeyAmber,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bottom Title & Subtitle + Arrow
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(11, 8, 9, 7),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: foreground,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: secondary,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: item.accent.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: item.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
