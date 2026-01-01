import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/widgets/widgets.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  IDCardStyle _selectedStyle = IDCardStyle.cute;

  Future<void> _pickAvatar() async {
    final pet = ref.read(currentPetProvider).valueOrNull;
    if (pet == null) return;

    final result = await ImagePickerHelper.showPicker(context);
    if (result != null) {
      try {
        await ref
            .read(petNotifierProvider.notifier)
            .updateAvatar(pet.id, result.bytes);
        if (mounted) {
          showAppNotification(context,
              message: 'Avatar updated!', type: NotificationType.success);
        }
      } catch (e) {
        if (mounted) {
          showAppNotification(context,
              message: 'Failed to update avatar', type: NotificationType.error);
        }
      }
    }
  }

  Future<void> _generateIDCard() async {
    final pet = ref.read(currentPetProvider).valueOrNull;
    if (pet == null) return;

    if (pet.avatarUrl == null || pet.avatarUrl!.isEmpty) {
      showAppNotification(context,
          message: 'Please upload a profile picture first!',
          type: NotificationType.error);
      return;
    }

    showAppNotification(context,
        message: 'Creating your pet\'s ID card...',
        type: NotificationType.info);

    // 调用 PetProfileNotifier 生成 ID Card
    await ref.read(petProfileNotifierProvider.notifier).generateIDCard(
          petId: pet.id,
          avatarBase64: pet.avatarUrl!,
          style: _selectedStyle,
        );

    // 检查结果
    final state = ref.read(petProfileNotifierProvider);
    if (mounted) {
      if (state.error != null) {
        showAppNotification(context,
            message: state.error!, type: NotificationType.error);
      } else if (state.generatedCard != null) {
        showAppNotification(context,
            message: 'ID Card created successfully!',
            type: NotificationType.success);
      }
    }
  }

  void _regenerateIDCard() {
    // 重置状态并重新生成
    ref.read(petProfileNotifierProvider.notifier).reset();
    _generateIDCard();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
            'Are you sure you want to sign out? Your local data will be preserved.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'This will permanently delete all your data. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final localStorage = ref.read(localStorageServiceProvider);
      await localStorage.signOut();
      ref.read(currentUserProvider.notifier).state = null;
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(currentPetProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: petAsync.when(
          loading: () => const Center(child: AppLoadingIndicator()),
          error: (e, _) => ErrorStateWidget(
            message: 'Failed to load profile',
            onRetry: () => ref.invalidate(currentPetProvider),
          ),
          data: (pet) {
            if (pet == null) {
              return const Center(child: Text('No pet selected'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProfileHeader(pet),
                  const SizedBox(height: 24),
                  _buildCardShopEntry(pet),
                  const SizedBox(height: 24),
                  _buildIDCardSection(pet),
                  const SizedBox(height: 24),
                  _buildStatsGrid(pet),
                  const SizedBox(height: 24),
                  _buildMedicalInfo(pet),
                  const SizedBox(height: 24),
                  _buildBodyPhotos(pet),
                  const SizedBox(height: 24),
                  _buildActions(),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Pet pet) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary400, AppColors.primary600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppShadows.primary(AppColors.primary500),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.5), width: 4),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1), blurRadius: 10)
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: pet.avatarUrl != null && pet.avatarUrl!.isNotEmpty
                      ? _buildAvatarImage(pet.avatarUrl!)
                      : Center(
                          child: Text(
                            pet.name.isNotEmpty
                                ? pet.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary500),
                          ),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1), blurRadius: 4)
                      ],
                    ),
                    child: Icon(Icons.camera_alt,
                        size: 18, color: AppColors.primary600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(pet.name,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getSpeciesIcon(pet.species),
                    size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text('${pet.species.displayName} • ${pet.breed}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.amber, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on,
                    size: 18, color: Colors.white),
                const SizedBox(width: 4),
                Text('${pet.coins} coins',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(String url) {
    if (url.startsWith('data:')) {
      final base64 = url.split(',').last;
      final bytes =
          Uri.parse('data:image/png;base64,$base64').data?.contentAsBytes();
      if (bytes != null) {
        return Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover);
      }
    }
    return Image.network(url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.pets));
  }

  Widget _buildCardShopEntry(Pet pet) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.cardShop),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.soft,
          border: Border.all(color: AppColors.primary100, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.amber.shade300, Colors.orange.shade400]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: const Icon(Icons.style, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pet Card Packs',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${pet.collection?.length ?? 0} cards collected',
                      style:
                          TextStyle(color: AppColors.stone500, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppColors.primary500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIDCardSection(Pet pet) {
    final idCardState = ref.watch(petProfileNotifierProvider);
    final isLoading = idCardState.isLoading;

    // 优先显示已保存的 ID Card
    final existingCard = pet.idCard;

    // 如果有已保存的卡或刚生成的卡，显示卡片
    if (existingCard != null) {
      return _buildExistingIDCard(pet, existingCard);
    }

    // 否则显示生成表单
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.soft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.badge, color: AppColors.primary500),
            const SizedBox(width: 8),
            const Text('Digital ID Card',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
          ]),
          const SizedBox(height: 16),

          // 风格选择
          Text('Choose Style',
              style: TextStyle(
                  color: AppColors.stone500,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: IDCardStyle.values.map((style) {
              final isSelected = _selectedStyle == style;
              return Expanded(
                child: GestureDetector(
                  onTap: isLoading
                      ? null
                      : () => setState(() => _selectedStyle = style),
                  child: Container(
                    margin: EdgeInsets.only(
                        right: style != IDCardStyle.values.last ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.primary500 : AppColors.stone50,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? null
                          : Border.all(color: AppColors.stone200),
                    ),
                    child: Text(style.displayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color:
                                isSelected ? Colors.white : AppColors.stone600,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // 生成按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _generateIDCard,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(isLoading ? 'Generating...' : 'Generate Magic ID'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ),

          // 提示信息
          const SizedBox(height: 12),
          if (!AppConfig.isAIConfigured)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.peach50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.peach100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.peach500, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add AI API key for AI-generated cartoon avatars',
                      style: TextStyle(color: AppColors.peach600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'AI will create a ${_selectedStyle.displayName.toLowerCase()} style avatar with personality tags',
              style: TextStyle(color: AppColors.stone400, fontSize: 12),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildExistingIDCard(Pet pet, PetIDCard card) {
    final idCardState = ref.watch(petProfileNotifierProvider);
    final isLoading = idCardState.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.badge, color: AppColors.primary500),
              const SizedBox(width: 8),
              const Text('Digital ID Card',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                card.style.displayName,
                style: TextStyle(
                    color: AppColors.primary600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ID Card 展示
        _buildIDCardDisplay(pet, card),

        const SizedBox(height: 20),

        // 重新生成部分
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.stone50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.stone100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Try a different style?',
                style: TextStyle(
                    color: AppColors.stone600,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              const SizedBox(height: 12),

              // 风格选择器
              Row(
                children: IDCardStyle.values.map((style) {
                  final isSelected = _selectedStyle == style;
                  final isCurrentStyle = card.style == style;
                  return Expanded(
                    child: GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => setState(() => _selectedStyle = style),
                      child: Container(
                        margin: EdgeInsets.only(
                            right: style != IDCardStyle.values.last ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.primary500 : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary500
                                : isCurrentStyle
                                    ? AppColors.primary200
                                    : AppColors.stone200,
                            width: isCurrentStyle ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              style.displayName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.stone600,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            if (isCurrentStyle) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Current',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white70
                                      : AppColors.primary400,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // 重新生成按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _regenerateIDCard,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(isLoading ? 'Generating...' : 'Regenerate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIDCardDisplay(Pet pet, PetIDCard card) {
    // 根据风格获取主题颜色
    final theme = _getCardTheme(card.style);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: theme.gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: theme.shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // 风格标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(top: 12, right: 12),
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${card.style.displayName} Edition',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 卡通头像
          Container(
            width: 140,
            height: 140,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 3),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: _buildCardImage(card.cartoonImageUrl),
            ),
          ),

          // 宠物名字
          Text(
            pet.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.textColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),

          // 性格描述
          if (card.description != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '"${card.description}"',
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.8),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 12),

          // 性格标签
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: card.tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                              color: theme.textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  _CardTheme _getCardTheme(IDCardStyle style) {
    switch (style) {
      case IDCardStyle.cool:
        return _CardTheme(
          gradient: LinearGradient(
            colors: [Colors.grey.shade900, Colors.purple.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          textColor: Colors.white,
          shadowColor: Colors.purple.shade900.withOpacity(0.4),
        );
      case IDCardStyle.pixel:
        return _CardTheme(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade700, Colors.blue.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          textColor: Colors.greenAccent,
          shadowColor: Colors.indigo.shade900.withOpacity(0.4),
        );
      case IDCardStyle.cute:
      default:
        return _CardTheme(
          gradient: LinearGradient(
            colors: [Colors.pink.shade100, Colors.pink.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          textColor: Colors.pink.shade800,
          shadowColor: Colors.pink.shade200.withOpacity(0.4),
        );
    }
  }

  Widget _buildCardImage(String url) {
    if (url.startsWith('data:')) {
      try {
        final base64Data = url.split(',').last;
        final bytes = base64Decode(base64Data);
        return Image.memory(Uint8List.fromList(bytes), fit: BoxFit.cover);
      } catch (e) {
        return const Center(
            child: Icon(Icons.broken_image, color: Colors.white54));
      }
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.pets, color: Colors.white54, size: 40)),
    );
  }

  Widget _buildStatsGrid(Pet pet) {
    return Row(children: [
      Expanded(
          child: _StatCard(
              label: 'Weight',
              value: '${pet.weightKg}',
              unit: 'kg',
              icon: Icons.monitor_weight,
              color: AppColors.sky500)),
      const SizedBox(width: 12),
      Expanded(
          child: _StatCard(
              label: 'Age',
              value: '${pet.ageMonths}',
              unit: 'mos',
              icon: Icons.cake,
              color: AppColors.peach500)),
      const SizedBox(width: 12),
      Expanded(
          child: _StatCard(
              label: 'Gender',
              value: pet.gender.displayName,
              unit: '',
              icon: pet.gender == PetGender.male ? Icons.male : Icons.female,
              color: AppColors.primary500)),
    ]);
  }

  Widget _buildMedicalInfo(Pet pet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.soft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.medical_services, color: AppColors.peach500),
            const SizedBox(width: 8),
            const Text('Medical Snapshot',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.stone50,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Neutered Status',
                    style: TextStyle(color: AppColors.stone600)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: pet.isNeutered
                          ? AppColors.mint100
                          : AppColors.stone200,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(pet.isNeutered ? 'Yes' : 'No',
                      style: TextStyle(
                          color: pet.isNeutered
                              ? AppColors.mint500
                              : AppColors.stone600,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Allergies',
              style: TextStyle(
                  color: AppColors.stone500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.peach50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.peach100)),
            child: Text(pet.allergies ?? 'No known allergies',
                style: TextStyle(
                    color: AppColors.peach500, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPhotos(Pet pet) {
    final parts = [
      BodyPart.eyes,
      BodyPart.ears,
      BodyPart.mouthTeeth,
      BodyPart.paws,
      BodyPart.skinFur
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.camera_alt, color: AppColors.primary500),
              const SizedBox(width: 8),
              const Text('Baseline Photos',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
            ]),
            TextButton(
                onPressed: () => showAppNotification(context,
                    message: 'Edit feature coming soon',
                    type: NotificationType.info),
                child: const Text('Edit')),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: parts.map((part) {
            final hasImage = pet.bodyPartImages?[part] != null;
            return Column(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.stone100, width: 2),
                      boxShadow: AppShadows.soft),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: hasImage
                          ? Image.network(pet.bodyPartImages![part]!,
                              fit: BoxFit.cover)
                          : Center(
                              child: Icon(Icons.camera_alt,
                                  color: AppColors.stone300))),
                ),
              ),
              const SizedBox(height: 4),
              Text(part.displayName,
                  style: TextStyle(
                      fontSize: 10,
                      color: AppColors.stone500,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.stone600,
              side: BorderSide(color: AppColors.stone300),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
          onPressed: _handleDeleteAccount,
          child: Text('Delete Account & Data',
              style: TextStyle(color: AppColors.error, fontSize: 13))),
      const SizedBox(height: 8),
      Text('PawPrint v1.0.0',
          style: TextStyle(color: AppColors.stone400, fontSize: 12)),
      if (AppConfig.useLocalMode)
        Text('Local Mode',
            style: TextStyle(
                color: AppColors.primary500,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
    ]);
  }

  IconData _getSpeciesIcon(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return Icons.pets;
      case PetSpecies.cat:
        return Icons.pets;
      case PetSpecies.bird:
        return Icons.flutter_dash;
      case PetSpecies.fish:
        return Icons.water;
      case PetSpecies.rabbit:
        return Icons.cruelty_free;
      default:
        return Icons.pets;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.unit,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.soft),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        if (unit.isNotEmpty)
          Text(unit, style: TextStyle(fontSize: 12, color: AppColors.stone400)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: AppColors.stone500,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// ID Card 主题配置
class _CardTheme {
  final LinearGradient gradient;
  final Color textColor;
  final Color shadowColor;

  const _CardTheme({
    required this.gradient,
    required this.textColor,
    required this.shadowColor,
  });
}
