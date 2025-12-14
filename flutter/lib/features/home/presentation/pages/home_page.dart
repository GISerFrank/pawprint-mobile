import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/models/models.dart';
import '../../../../core/config/app_config.dart';
import '../../../../shared/widgets/widgets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(currentPetProvider);
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: petAsync.when(
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (e, _) => ErrorStateWidget(
            message: 'Failed to load pet data',
            onRetry: () => ref.invalidate(currentPetProvider),
          ),
          data: (pet) {
            if (pet == null) {
              return _NoPetView();
            }
            return _HomeContent(
              pet: pet,
              remindersAsync: remindersAsync,
            );
          },
        ),
      ),
    );
  }
}

/// 没有宠物时的视图
class _NoPetView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primary100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets,
                size: 64,
                color: AppColors.primary500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Pet Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your furry friend to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.stone500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryGradientButton(
              label: 'Add Pet',
              icon: Icons.add,
              onPressed: () => context.go(AppRoutes.onboarding),
            ),
          ],
        ),
      ),
    );
  }
}

/// 主页内容
class _HomeContent extends ConsumerWidget {
  final Pet pet;
  final AsyncValue<List<Reminder>> remindersAsync;

  const _HomeContent({
    required this.pet,
    required this.remindersAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(currentPetProvider);
        ref.invalidate(remindersProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _Header(petName: pet.name),
            const SizedBox(height: 24),

            // Pet Card
            _PetCard(pet: pet),
            const SizedBox(height: 24),

            // Quick Stats
            _QuickStats(pet: pet),
            const SizedBox(height: 24),

            // Upcoming Reminders
            _UpcomingReminders(remindersAsync: remindersAsync),
            const SizedBox(height: 24),

            // Quick Actions
            _QuickActions(),
            const SizedBox(height: 24),

            // Tips Section
            _HealthTips(species: pet.species),

            const SizedBox(height: 100), // Bottom nav padding
          ],
        ),
      ),
    );
  }
}

/// 顶部 Header
class _Header extends StatelessWidget {
  final String petName;

  const _Header({required this.petName});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting()} 👋',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.stone500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '$petName\'s Home',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        // Local mode indicator
        if (AppConfig.useLocalMode)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.sky100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.offline_bolt, size: 16, color: AppColors.sky500),
                SizedBox(width: 4),
                Text(
                  'Local',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sky500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 宠物卡片
class _PetCard extends StatelessWidget {
  final Pet pet;

  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary400, AppColors.primary600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppShadows.primary(AppColors.primary500),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white30, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: pet.avatarUrl != null && pet.avatarUrl!.isNotEmpty
                  ? _buildAvatar(pet.avatarUrl!)
                  : Icon(
                      Icons.pets,
                      size: 40,
                      color: Colors.white.withOpacity(0.8),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.species.displayName} • ${pet.breed}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 12),
                // Coins badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on,
                          size: 18, color: Colors.amber[300]),
                      const SizedBox(width: 6),
                      Text(
                        '${pet.coins} Coins',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Profile button
          IconButton(
            onPressed: () => context.go(AppRoutes.profile),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String url) {
    // Handle base64 data URLs (local mode)
    if (url.startsWith('data:image')) {
      try {
        final uri = Uri.parse(url);
        if (uri.data != null) {
          return Image.memory(
            uri.data!.contentAsBytes(),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _defaultIcon(),
          );
        }
      } catch (_) {}
      return _defaultIcon();
    }
    // Handle network URLs
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => _defaultIcon(),
    );
  }

  Widget _defaultIcon() {
    return Icon(
      Icons.pets,
      size: 40,
      color: Colors.white.withOpacity(0.8),
    );
  }
}

/// 快速统计
class _QuickStats extends StatelessWidget {
  final Pet pet;

  const _QuickStats({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.cake_outlined,
            label: 'Age',
            value: _formatAge(pet.ageMonths),
            color: AppColors.peach100,
            iconColor: AppColors.peach500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.monitor_weight_outlined,
            label: 'Weight',
            value: '${pet.weightKg.toStringAsFixed(1)} kg',
            color: AppColors.sky100,
            iconColor: AppColors.sky500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: pet.gender == PetGender.male ? Icons.male : Icons.female,
            label: 'Gender',
            value: pet.gender.displayName,
            color: AppColors.mint100,
            iconColor: AppColors.mint500,
          ),
        ),
      ],
    );
  }

  String _formatAge(int months) {
    if (months < 12) {
      return '$months mo';
    }
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) {
      return '$years yr';
    }
    return '$years yr $remainingMonths mo';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.stone800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.stone500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 即将到来的提醒
class _UpcomingReminders extends StatelessWidget {
  final AsyncValue<List<Reminder>> remindersAsync;

  const _UpcomingReminders({required this.remindersAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.records),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        remindersAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => _EmptyReminders(),
          data: (reminders) {
            final upcoming = reminders
                .where((r) =>
                    !r.isCompleted && r.scheduledAt.isAfter(DateTime.now()))
                .take(3)
                .toList();

            if (upcoming.isEmpty) {
              return _EmptyReminders();
            }

            return Column(
              children:
                  upcoming.map((r) => _ReminderTile(reminder: r)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyReminders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stone100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.stone50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_available, color: AppColors.stone400),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All caught up!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.stone700,
                  ),
                ),
                Text(
                  'No upcoming reminders',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.stone500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;

  const _ReminderTile({required this.reminder});

  IconData _getIcon() {
    switch (reminder.reminderType) {
      case ReminderType.appointment:
        return Icons.calendar_today;
      case ReminderType.medication:
        return Icons.medication;
      case ReminderType.grooming:
        return Icons.content_cut;
      case ReminderType.other:
        return Icons.notifications;
    }
  }

  Color _getColor() {
    switch (reminder.reminderType) {
      case ReminderType.appointment:
        return AppColors.primary500;
      case ReminderType.medication:
        return AppColors.peach500;
      case ReminderType.grooming:
        return AppColors.mint500;
      case ReminderType.other:
        return AppColors.sky500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final isToday = _isToday(reminder.scheduledAt);
    final isTomorrow = _isTomorrow(reminder.scheduledAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
        border: isToday
            ? Border.all(color: color.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getIcon(), color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.stone800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(reminder.scheduledAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.stone500,
                  ),
                ),
              ],
            ),
          ),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (isTomorrow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.stone100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Tomorrow',
                style: TextStyle(
                  color: AppColors.stone600,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  String _formatDate(DateTime date) {
    if (_isToday(date)) {
      return 'Today at ${_formatTime(date)}';
    } else if (_isTomorrow(date)) {
      return 'Tomorrow at ${_formatTime(date)}';
    } else {
      return '${date.month}/${date.day} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

/// 快速操作
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.timeline,
                label: 'Timeline',
                color: AppColors.sky100,
                iconColor: AppColors.sky500,
                onTap: () => context.go(AppRoutes.records),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.auto_awesome,
                label: 'AI Vet',
                color: AppColors.mint100,
                iconColor: AppColors.mint500,
                onTap: () => context.go(AppRoutes.analysis),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.style,
                label: 'Cards',
                color: AppColors.peach100,
                iconColor: AppColors.peach500,
                onTap: () => context.push(AppRoutes.cardShop),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// 健康小贴士
class _HealthTips extends StatelessWidget {
  final PetSpecies species;

  const _HealthTips({required this.species});

  List<Map<String, String>> _getTips() {
    switch (species) {
      case PetSpecies.dog:
        return [
          {
            'title': 'Daily Exercise',
            'desc': 'Dogs need 30-60 min of activity daily',
            'icon': '🏃'
          },
          {
            'title': 'Dental Care',
            'desc': 'Brush teeth 2-3 times per week',
            'icon': '🦷'
          },
          {
            'title': 'Social Time',
            'desc': 'Regular interaction prevents anxiety',
            'icon': '🐕'
          },
        ];
      case PetSpecies.cat:
        return [
          {
            'title': 'Hydration',
            'desc': 'Cats often need encouragement to drink',
            'icon': '💧'
          },
          {
            'title': 'Scratching Post',
            'desc': 'Essential for claw health',
            'icon': '🐱'
          },
          {
            'title': 'Quiet Time',
            'desc': 'Cats need 12-16 hours of sleep',
            'icon': '😴'
          },
        ];
      default:
        return [
          {
            'title': 'Regular Checkups',
            'desc': 'Visit the vet annually',
            'icon': '🩺'
          },
          {
            'title': 'Balanced Diet',
            'desc': 'Species-appropriate nutrition',
            'icon': '🥗'
          },
          {
            'title': 'Clean Environment',
            'desc': 'Regular habitat maintenance',
            'icon': '🧹'
          },
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tips = _getTips();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Tips',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final tip = tips[index];
              return Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      index == 0
                          ? AppColors.primary50
                          : index == 1
                              ? AppColors.peach100.withOpacity(0.5)
                              : AppColors.mint100.withOpacity(0.5),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.stone100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip['icon']!,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip['title']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.stone800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip['desc']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.stone500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
