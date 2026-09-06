import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/services/user_progress_service.dart';
import '../../data/analytics_aggregations.dart';

/// A-5: a single card showing the last 7 days of activity as a
/// bar-chart-style trend strip (top) and a row of streak dots
/// (bottom). The strip's height encodes per-day accuracy; the
/// dots light up on days with at least one session.
///
/// Both halves are derived from the same [dayRollups] list so they
/// always agree, and the card stays empty (but visible) when the
/// user has never opened the app — a blank baseline is more
/// inviting than a missing card.
class WeeklyTrendCard extends StatelessWidget {
  final List<SessionRecord> history;

  const WeeklyTrendCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final days = AnalyticsAggregations.last7Days(history);
    final activeDays = days.where((d) => d.hasActivity).length;
    final totalQs = days.fold<int>(0, (a, d) => a + d.questions);
    final activeAccuracies = days
        .where((d) => d.avgAccuracy != null)
        .map((d) => d.avgAccuracy!)
        .toList();
    final weekAvg = activeAccuracies.isEmpty
        ? 0
        : activeAccuracies.reduce((a, b) => a + b) / activeAccuracies.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: palette.primarySubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.show_chart_rounded,
                      color: palette.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.primarySubtle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$activeDays / 7 days active',
                  style: TextStyle(
                    color: palette.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // The trend strip itself.
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in days)
                  Expanded(
                    child: _DayBar(
                      day: d,
                      primary: palette.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Day labels under the strip.
          Row(
            children: [
              for (final d in days)
                Expanded(
                  child: Text(
                    _weekdayLabel(d.day),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _isToday(d.day)
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // Streak dots row + summary.
          Row(
            children: [
              for (final d in days)
                Expanded(
                  child: _StreakDot(
                    day: d,
                    isToday: _isToday(d.day),
                    primary: palette.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            activeDays == 0
                ? 'No practice yet this week — solve a question to start your streak.'
                : 'Week average: ${weekAvg.round()}% accuracy • $totalQs question${totalQs == 1 ? '' : 's'} solved',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  String _weekdayLabel(DateTime d) {
    // Display M T W T F S S (Monday-first, matching most calendars).
    return _weekdays[(d.weekday - 1) % 7];
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _DayBar extends StatelessWidget {
  final DayRollup day;
  final Color primary;

  const _DayBar({required this.day, required this.primary});

  @override
  Widget build(BuildContext context) {
    final hasData = day.avgAccuracy != null;
    final value = day.avgAccuracy ?? 0;
    // Reserve a 2px sliver of height so empty days still register as
    // a faint baseline instead of being invisible.
    final heightPct = hasData
        ? (value / 100).clamp(0.05, 1.0)
        : 0.04;
    final color = hasData
        ? primary
        : AppColors.surfaceElevated;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasData)
              Text(
                '${value.round()}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 70 * heightPct,
              decoration: BoxDecoration(
                gradient: hasData
                    ? LinearGradient(
                        colors: [
                          primary.withValues(alpha: 0.7),
                          primary,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      )
                    : null,
                color: hasData ? null : color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakDot extends StatelessWidget {
  final DayRollup day;
  final bool isToday;
  final Color primary;

  const _StreakDot({
    required this.day,
    required this.isToday,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final filled = day.hasActivity;
    final Color color;
    final border = Border.all(
      color: isToday ? primary : AppColors.border,
      width: isToday ? 2 : 1,
    );
    if (filled) {
      color = primary;
    } else {
      color = AppColors.surfaceElevated;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: border,
            ),
            child: filled
                ? const Icon(
                    Icons.check_rounded,
                    size: 11,
                    color: AppColors.textOnPrimary,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
