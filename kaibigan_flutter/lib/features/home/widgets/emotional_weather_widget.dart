import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../mood_tracking/mood_model.dart';

class EmotionalWeatherWidget extends StatelessWidget {
  final EmotionalWeatherInfo weather;
  const EmotionalWeatherWidget({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    // Day tracker setup
    final weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    // Dart: Monday = 1, Sunday = 7.
    // Shifted to match Sun-Sat: Sun=0 (index 0), Mon=1 (index 1), ..., Sat=6 (index 6)
    final currentDay = DateTime.now().weekday;
    final highlightIndex = currentDay == 7 ? 0 : currentDay; // Sun=7 in Dart -> index 0

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF5E5B52), // Quabble Olive Taupe
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Highlight - ${weather.title.toLowerCase()}",
            style: GoogleFonts.quicksand(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD6D3CB),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            weather.description.split(' ').first, // e.g. "Productive"
            style: GoogleFonts.quicksand(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Weekday circles
              Row(
                children: List.generate(weekdays.length, (index) {
                  final isToday = index == highlightIndex;
                  return Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.white : const Color(0xFF706C62),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        weekdays[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isToday ? const Color(0xFF5E5B52) : const Color(0xFFC5C2BA),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              // My Routines badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6F6C63),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'My Routines',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFECEAE4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

