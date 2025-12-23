import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/pet_theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/pet_theme_provider.dart';
import 'draggable_bottom_sheet.dart';

/// 宠物头像按钮 - 点击打开切换面板
class PetAvatarButton extends ConsumerWidget {
  final double size;
  final bool showBorder;

  const PetAvatarButton({
    super.key,
    this.size = 40,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(currentPetProvider);
    final theme = ref.petTheme;

    return GestureDetector(
      onTap: () => _showPetSwitcher(context),
      child: petAsync.when(
        loading: () => _buildAvatar(null, null, theme),
        error: (_, __) => _buildAvatar(null, null, theme),
        data: (pet) => _buildAvatar(pet?.avatarUrl, pet?.name, theme),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String? name, PetTheme theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: theme.gradient,
        border: showBorder ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(name, theme),
              )
            : _buildPlaceholder(name, theme),
      ),
    );
  }

  Widget _buildPlaceholder(String? name, PetTheme theme) {
    return Container(
      color: theme.primaryLight,
      child: Center(
        child: Text(
          name?.isNotEmpty == true ? name![0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.primary,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  void _showPetSwitcher(BuildContext context) {
    showDraggableBottomSheet(
      context: context,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      child: const PetSwitcherSheetContent(),
    );
  }
}

/// 宠物切换面板内容
class PetSwitcherSheetContent extends ConsumerWidget {
  const PetSwitcherSheetContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petsListProvider);
    final selectedPetId = ref.watch(selectedPetIdProvider);
    final theme = ref.petTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: theme.gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pets, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'My Pets',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            // Add Pet Button
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/onboarding');
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                foregroundColor: theme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 8),

        // Pet List
        petsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('Failed to load pets'),
            ),
          ),
          data: (pets) {
            if (pets.isEmpty) {
              return _buildEmptyState(context, theme);
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: pets.map((pet) {
                final isSelected = pet.id == selectedPetId;
                final petTheme = PetTheme.fromSpecies(pet.species);
                return _PetListItem(
                  pet: pet,
                  isSelected: isSelected,
                  theme: petTheme,
                  onTap: () {
                    ref.read(selectedPetIdProvider.notifier).state = pet.id;
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, PetTheme theme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pets, size: 48, color: theme.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'No pets yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first pet to get started',
            style: TextStyle(color: AppColors.stone500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/onboarding');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Pet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PetListItem extends StatelessWidget {
  final Pet pet;
  final bool isSelected;
  final PetTheme theme;
  final VoidCallback onTap;

  const _PetListItem({
    required this.pet,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: theme.primary, width: 2) : null,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: theme.gradient,
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: pet.avatarUrl != null && pet.avatarUrl!.isNotEmpty
                    ? Image.network(
                        pet.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                      )
                    : _buildAvatarPlaceholder(),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pet.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected ? theme.primary : AppColors.stone800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(theme.emoji, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _InfoChip(
                        label: pet.species.displayName,
                        color: theme.primary,
                      ),
                      const SizedBox(width: 8),
                      if (pet.breed != 'Unknown')
                        _InfoChip(
                          label: pet.breed,
                          color: AppColors.stone500,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Health Status & Selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  )
                else
                  const SizedBox(height: 24),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pet.isSick ? AppColors.peach100 : AppColors.mint100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pet.isSick ? Icons.healing : Icons.favorite,
                        size: 12,
                        color: pet.isSick ? AppColors.peach500 : AppColors.mint500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pet.isSick ? 'Sick' : 'Healthy',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: pet.isSick ? AppColors.peach600 : AppColors.mint600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: theme.primaryLight,
      child: Center(
        child: Text(
          pet.name.isNotEmpty ? pet.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 顶部导航栏 - 带宠物切换功能
class PetAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showPetSwitcher;
  final bool centerTitle;

  const PetAppBar({
    super.key,
    this.title,
    this.actions,
    this.showPetSwitcher = true,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(currentPetProvider);
    final theme = ref.petTheme;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      leading: showPetSwitcher
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: PetAvatarButton(size: 40),
            )
          : null,
      title: title != null
          ? Text(title!)
          : showPetSwitcher
              ? petAsync.when(
                  loading: () => const Text('Loading...'),
                  error: (_, __) => const Text('PawPrint'),
                  data: (pet) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pet?.name ?? 'PawPrint',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(theme.emoji),
                    ],
                  ),
                )
              : null,
      actions: [
        if (actions != null) ...actions!,
        if (showPetSwitcher)
          IconButton(
            onPressed: () => _showPetSwitcher(context),
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch Pet',
          ),
      ],
    );
  }

  void _showPetSwitcher(BuildContext context) {
    showDraggableBottomSheet(
      context: context,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      child: const PetSwitcherSheetContent(),
    );
  }
}
