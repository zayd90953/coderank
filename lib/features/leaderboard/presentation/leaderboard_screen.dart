import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../shared/services/firebase_user_util.dart';
import '../../../../shared/services/user_progress_service.dart';
import '../../../../shared/widgets/back_button_to_home.dart';

class LeaderboardEntry {
  final int rank;
  final String name;
  final String avatarText;
  final int xp;
  final int accuracy;
  final int streak;
  final String college;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.avatarText,
    required this.xp,
    required this.accuracy,
    required this.streak,
    required this.college,
    this.isCurrentUser = false,
  });
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 0; // 0: Weekly, 1: All-Time, 2: Subject

  @override
  Widget build(BuildContext context) {
    final palette = ColorPaletteController.instance.current;
    final user = firebaseCurrentUserOrNull();
    final currentUserName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : "You";

    return ValueListenableBuilder<UserProgressData>(
      valueListenable: UserProgressService.instance.progressNotifier,
      builder: (context, data, _) {
        final userXp = data.xpPoints;
        final userAcc = data.overallAccuracy.round();
        final userStreak = data.streakDays;

        // Calculate dynamic rank for user in the mock NEET cohort
        final dynamicLeaderboard = _buildLeaderboard(
          currentUserName: currentUserName,
          userXp: userXp,
          userAcc: userAcc,
          userStreak: userStreak,
          tabIndex: _selectedTab,
        );

        final currentUserRank = dynamicLeaderboard
            .firstWhere(
              (e) => e.isCurrentUser,
              orElse: () => LeaderboardEntry(
                rank: 12,
                name: currentUserName,
                avatarText: currentUserName.substring(0, 1).toUpperCase(),
                xp: userXp,
                accuracy: userAcc,
                streak: userStreak,
                college: "Target AIIMS Delhi",
                isCurrentUser: true,
              ),
            )
            .rank;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            // Always show a back button — pops if pushed, switches to Home
            // when this screen is the active tab.
            leading: const BackButtonToHome(),
            title: Text(
              "NEET Leaderboard",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Segmented Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(0, "Weekly Sprint"),
                      _buildTabButton(1, "All-Time Elite"),
                      _buildTabButton(2, "Subject Champs"),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
                  child: Column(
                    children: [
                      // Top 3 Podium
                      if (dynamicLeaderboard.length >= 3)
                        _buildPodium(
                          first: dynamicLeaderboard[0],
                          second: dynamicLeaderboard[1],
                          third: dynamicLeaderboard[2],
                        ),

                      const SizedBox(height: 24),

                      // Rest of Rankings
                      ...dynamicLeaderboard.skip(3).map((entry) {
                        return _buildRankingRow(entry);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Pinned Bottom User Bar
          bottomSheet: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "#$currentUserRank",
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: palette.primarySubtle,
                    child: Text(
                      currentUserName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: palette.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$currentUserName (You)",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "$userAcc% accuracy • ${data.tier} Tier",
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: Color(0xFFD97706),
                            size: 16,
                          ),
                          Text(
                            "$userXp XP",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "🔥 ${userStreak}d streak",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF6B00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(int index, String title) {
    final palette = ColorPaletteController.instance.current;
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? palette.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodium({
    required LeaderboardEntry first,
    required LeaderboardEntry second,
    required LeaderboardEntry third,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          _buildPodiumPillar(
            entry: second,
            height: 90,
            badgeColor: const Color(0xFF94A3B8),
            badgeLabel: "2nd",
            medalColor: const Color(0xFFCBD5E1),
          ),
          // 1st Place (Center & Tallest)
          _buildPodiumPillar(
            entry: first,
            height: 125,
            badgeColor: const Color(0xFFFFB800),
            badgeLabel: "1st 👑",
            medalColor: const Color(0xFFFFD166),
            isFirst: true,
          ),
          // 3rd Place
          _buildPodiumPillar(
            entry: third,
            height: 75,
            badgeColor: const Color(0xFFD97706),
            badgeLabel: "3rd",
            medalColor: const Color(0xFFFDE68A),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPillar({
    required LeaderboardEntry entry,
    required double height,
    required Color badgeColor,
    required String badgeLabel,
    required Color medalColor,
    bool isFirst = false,
  }) {
    final palette = ColorPaletteController.instance.current;
    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isFirst
                    ? AppColors.goldGradient
                    : LinearGradient(
                        colors: [badgeColor, badgeColor.withValues(alpha: 0.7)],
                      ),
              ),
              child: CircleAvatar(
                radius: isFirst ? 28 : 22,
                backgroundColor: Colors.white,
                child: Text(
                  entry.avatarText,
                  style: TextStyle(
                    // Dark initial on the white medal circle — white text
                    // would be invisible here in dark mode too.
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: isFirst ? 18 : 14,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 80,
          child: Text(
            entry.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: entry.isCurrentUser
                  ? palette.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          "${entry.xp} XP",
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD97706),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 70,
          height: height,
          decoration: BoxDecoration(
            color: medalColor.withValues(alpha: 0.25),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(color: medalColor.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Text(
            "${entry.accuracy}% acc",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingRow(LeaderboardEntry entry) {
    final palette = ColorPaletteController.instance.current;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? palette.primarySubtle
            : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: entry.isCurrentUser
              ? palette.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline,
          width: entry.isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              "#${entry.rank}",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: entry.isCurrentUser
                    ? palette.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: entry.isCurrentUser
                ? palette.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              entry.avatarText,
              style: TextStyle(
                color: entry.isCurrentUser
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name + (entry.isCurrentUser ? " (You)" : ""),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: entry.isCurrentUser
                        ? palette.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${entry.college} • ${entry.accuracy}% acc",
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${entry.xp} XP",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                "🔥 ${entry.streak}d",
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFFF6B00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<LeaderboardEntry> _buildLeaderboard({
    required String currentUserName,
    required int userXp,
    required int userAcc,
    required int userStreak,
    required int tabIndex,
  }) {
    // Standard base high achievers in NEET cohort
    final List<Map<String, dynamic>> peers = [
      {"name": "Ananya Sharma", "xp": 4820, "acc": 96, "streak": 14, "college": "Target AIIMS Delhi"},
      {"name": "Rohan Verma", "xp": 4210, "acc": 93, "streak": 11, "college": "Target JIPMER"},
      {"name": "Priya Nair", "xp": 3650, "acc": 91, "streak": 9, "college": "Target CMC Vellore"},
      {"name": "Aarav Patel", "xp": 3100, "acc": 88, "streak": 7, "college": "Target KGMU"},
      {"name": "Sneha Kulkarni", "xp": 2740, "acc": 86, "streak": 6, "college": "Target BJ Medical"},
      {"name": "Vikram Singh", "xp": 2300, "acc": 84, "streak": 5, "college": "Target IMS BHU"},
      {"name": "Devika Rao", "xp": 1850, "acc": 82, "streak": 4, "college": "Target Madras Medical"},
      {"name": "Kabir Mehta", "xp": 1420, "acc": 79, "streak": 3, "college": "Target Seth GS"},
      {"name": "Tanvi Joshi", "xp": 980, "acc": 76, "streak": 2, "college": "Target Lady Hardinge"},
      {"name": "Arjun Das", "xp": 650, "acc": 73, "streak": 2, "college": "Target SMS Jaipur"},
    ];

    final userEntry = {
      "name": currentUserName,
      "xp": userXp,
      "acc": userAcc == 0 ? 70 : userAcc,
      "streak": userStreak,
      "college": "Target AIIMS Delhi",
      "isCurrentUser": true,
    };

    final all = [...peers, userEntry];
    all.sort((a, b) => (b["xp"] as int).compareTo(a["xp"] as int));

    return List.generate(all.length, (index) {
      final item = all[index];
      final name = item["name"] as String;
      return LeaderboardEntry(
        rank: index + 1,
        name: name,
        avatarText: name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "S",
        xp: item["xp"] as int,
        accuracy: item["acc"] as int,
        streak: item["streak"] as int,
        college: item["college"] as String,
        isCurrentUser: item["isCurrentUser"] == true,
      );
    });
  }
}
