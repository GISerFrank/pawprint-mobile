import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'service_providers.dart';
import 'auth_provider.dart';

/// 当前选中的宠物 ID
final selectedPetIdProvider = StateProvider<String?>((ref) => null);

/// 用户的所有宠物列表
final petsListProvider = FutureProvider<List<Pet>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageServiceProvider);
    return localStorage.getPets();
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getPets();
  }
});

/// 当前选中的宠物详情
final currentPetProvider = FutureProvider<Pet?>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);

  if (petId == null) {
    // 如果没有选中，尝试获取第一个宠物
    final pets = await ref.watch(petsListProvider.future);
    if (pets.isEmpty) return null;

    // 自动选中第一个
    ref.read(selectedPetIdProvider.notifier).state = pets.first.id;
    return pets.first;
  }

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageServiceProvider);
    return localStorage.getPetById(petId);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getPetById(petId);
  }
});

/// 宠物管理 Notifier
class PetNotifier extends StateNotifier<AsyncValue<Pet?>> {
  final Ref _ref;

  PetNotifier(this._ref) : super(const AsyncValue.loading());

  /// 创建新宠物
  Future<Pet> createPet({
    required String name,
    required PetSpecies species,
    String breed = 'Unknown',
    int ageMonths = 0,
    PetGender gender = PetGender.male,
    double weightKg = 0,
    bool isNeutered = false,
    String? allergies,
    Uint8List? avatarBytes,
    Map<BodyPart, Uint8List>? bodyPartImages,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('User not authenticated');

    String? avatarUrl;

    // 处理头像
    if (avatarBytes != null) {
      if (AppConfig.useLocalMode) {
        final localStorage = _ref.read(localStorageServiceProvider);
        final key = '${user.id}_avatar_${DateTime.now().millisecondsSinceEpoch}';
        avatarUrl = await localStorage.saveImageLocally(key, avatarBytes);
      } else {
        final storage = _ref.read(storageServiceProvider);
        avatarUrl = await storage.uploadPetAvatar(
          petId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          fileBytes: avatarBytes,
        );
      }
    }

    // 创建宠物
    final newPet = Pet(
      id: '',
      userId: user.id,
      name: name,
      species: species,
      breed: breed,
      ageMonths: ageMonths,
      gender: gender,
      weightKg: weightKg,
      isNeutered: isNeutered,
      allergies: allergies,
      avatarUrl: avatarUrl,
      coins: AppConfig.initialCoins,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Pet createdPet;

    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      createdPet = await localStorage.createPet(newPet);

      // 处理身体部位图片
      if (bodyPartImages != null) {
        for (final entry in bodyPartImages.entries) {
          final key = '${createdPet.id}_${entry.key.displayName}';
          await localStorage.saveImageLocally(key, entry.value);
        }
      }
    } else {
      final db = _ref.read(databaseServiceProvider);
      createdPet = await db.createPet(newPet);

      // 更新头像 URL
      if (avatarBytes != null) {
        final storage = _ref.read(storageServiceProvider);
        avatarUrl = await storage.uploadPetAvatar(
          petId: createdPet.id,
          fileBytes: avatarBytes,
        );
        createdPet = await db.updatePet(createdPet.id, {'avatar_url': avatarUrl});
      }

      // 处理身体部位图片
      if (bodyPartImages != null) {
        final storage = _ref.read(storageServiceProvider);
        for (final entry in bodyPartImages.entries) {
          final imageUrl = await storage.uploadBodyPartImage(
            petId: createdPet.id,
            bodyPart: entry.key.displayName,
            fileBytes: entry.value,
          );
          await db.upsertPetBodyImage(
            petId: createdPet.id,
            bodyPart: entry.key,
            imageUrl: imageUrl,
          );
        }
      }
    }

    // 选中新创建的宠物
    _ref.read(selectedPetIdProvider.notifier).state = createdPet.id;

    // 刷新列表
    _ref.invalidate(petsListProvider);

    return createdPet;
  }

  /// 更新宠物信息
  Future<Pet> updatePet(String petId, Map<String, dynamic> updates) async {
    Pet updatedPet;

    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      updatedPet = await localStorage.updatePet(petId, updates);
    } else {
      final db = _ref.read(databaseServiceProvider);
      updatedPet = await db.updatePet(petId, updates);
    }

    _ref.invalidate(currentPetProvider);
    _ref.invalidate(petsListProvider);
    return updatedPet;
  }

  /// 更新宠物头像
  Future<String> updateAvatar(String petId, Uint8List imageBytes) async {
    String avatarUrl;

    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      final key = '${petId}_avatar_${DateTime.now().millisecondsSinceEpoch}';
      avatarUrl = await localStorage.saveImageLocally(key, imageBytes);
      await localStorage.updatePet(petId, {'avatar_url': avatarUrl});
    } else {
      final storage = _ref.read(storageServiceProvider);
      final db = _ref.read(databaseServiceProvider);
      avatarUrl = await storage.uploadPetAvatar(petId: petId, fileBytes: imageBytes);
      await db.updatePet(petId, {'avatar_url': avatarUrl});
    }

    _ref.invalidate(currentPetProvider);
    return avatarUrl;
  }

  /// 更新金币
  Future<void> updateCoins(String petId, int coins) async {
    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      await localStorage.updateCoins(petId, coins);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.updateCoins(petId, coins);
    }
    _ref.invalidate(currentPetProvider);
  }

  /// 删除宠物
  Future<void> deletePet(String petId) async {
    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      await localStorage.deletePet(petId);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.deletePet(petId);
    }

    // 清除选中状态
    if (_ref.read(selectedPetIdProvider) == petId) {
      _ref.read(selectedPetIdProvider.notifier).state = null;
    }

    _ref.invalidate(petsListProvider);
    _ref.invalidate(currentPetProvider);
  }
}

/// 宠物管理 Provider
final petNotifierProvider = StateNotifierProvider<PetNotifier, AsyncValue<Pet?>>((ref) {
  return PetNotifier(ref);
});

/// 是否已完成 Onboarding
final hasCompletedOnboardingProvider = FutureProvider<bool>((ref) async {
  final pets = await ref.watch(petsListProvider.future);
  return pets.isNotEmpty;
});