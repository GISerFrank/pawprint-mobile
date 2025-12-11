import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../config/app_config.dart';

/// 本地存储服务 - 模拟后端数据存储
/// 用于在没有 Supabase 连接时进行本地开发和测试
class LocalStorageService {
  static const String _keyCurrentUser = 'local_current_user';
  static const String _keyPets = 'local_pets';
  static const String _keyHealthRecords = 'local_health_records';
  static const String _keyReminders = 'local_reminders';
  static const String _keyAIAnalysisSessions = 'local_ai_sessions';
  static const String _keyForumPosts = 'local_forum_posts';
  static const String _keyCollectibleCards = 'local_collectible_cards';

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// 初始化
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // ============================================
  // 用户认证模拟
  // ============================================

  Future<LocalUser?> getCurrentUser() async {
    await init();
    final json = _prefs.getString(_keyCurrentUser);
    if (json == null) return null;
    return LocalUser.fromJson(jsonDecode(json));
  }

  Future<LocalUser> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    await init();
    final user = LocalUser(
      id: _generateId(),
      email: email,
      name: name ?? email.split('@').first,
      createdAt: DateTime.now(),
    );
    await _prefs.setString(_keyCurrentUser, jsonEncode(user.toJson()));
    return user;
  }

  Future<LocalUser> signIn({
    required String email,
    required String password,
  }) async {
    await init();
    // 在本地模式下，任何邮箱密码都可以登录
    var user = await getCurrentUser();
    if (user == null || user.email != email) {
      user = LocalUser(
        id: _generateId(),
        email: email,
        name: email.split('@').first,
        createdAt: DateTime.now(),
      );
    }
    await _prefs.setString(_keyCurrentUser, jsonEncode(user.toJson()));
    return user;
  }

  Future<void> signOut() async {
    await init();
    await _prefs.remove(_keyCurrentUser);
  }

  // ============================================
  // 宠物管理
  // ============================================

  Future<List<Pet>> getPets() async {
    await init();
    final user = await getCurrentUser();
    if (user == null) return [];

    final json = _prefs.getString(_keyPets);
    if (json == null) return [];

    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => Pet.fromJson(e))
        .where((p) => p.userId == user.id)
        .toList();
  }

  Future<Pet?> getPetById(String petId) async {
    final pets = await getPets();
    try {
      return pets.firstWhere((p) => p.id == petId);
    } catch (_) {
      return null;
    }
  }

  Future<Pet> createPet(Pet pet) async {
    await init();
    final user = await getCurrentUser();
    if (user == null) throw Exception('User not authenticated');

    final newPet = pet.copyWith(
      id: _generateId(),
      userId: user.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final pets = await _getAllPets();
    pets.add(newPet);
    await _savePets(pets);

    return newPet;
  }

  Future<Pet> updatePet(String petId, Map<String, dynamic> updates) async {
    final pets = await _getAllPets();
    final index = pets.indexWhere((p) => p.id == petId);
    if (index == -1) throw Exception('Pet not found');

    final oldPet = pets[index];
    final updatedPet = Pet(
      id: oldPet.id,
      userId: oldPet.userId,
      name: updates['name'] ?? oldPet.name,
      species: updates['species'] != null
          ? PetSpecies.fromString(updates['species'])
          : oldPet.species,
      breed: updates['breed'] ?? oldPet.breed,
      ageMonths: updates['age_months'] ?? oldPet.ageMonths,
      gender: updates['gender'] != null
          ? PetGender.fromString(updates['gender'])
          : oldPet.gender,
      weightKg: updates['weight_kg']?.toDouble() ?? oldPet.weightKg,
      isNeutered: updates['is_neutered'] ?? oldPet.isNeutered,
      allergies: updates['allergies'] ?? oldPet.allergies,
      avatarUrl: updates['avatar_url'] ?? oldPet.avatarUrl,
      coins: updates['coins'] ?? oldPet.coins,
      createdAt: oldPet.createdAt,
      updatedAt: DateTime.now(),
    );

    pets[index] = updatedPet;
    await _savePets(pets);
    return updatedPet;
  }

  Future<void> deletePet(String petId) async {
    final pets = await _getAllPets();
    pets.removeWhere((p) => p.id == petId);
    await _savePets(pets);
  }

  Future<void> updateCoins(String petId, int coins) async {
    await updatePet(petId, {'coins': coins});
  }

  Future<List<Pet>> _getAllPets() async {
    await init();
    final json = _prefs.getString(_keyPets);
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list.map((e) => Pet.fromJson(e)).toList();
  }

  Future<void> _savePets(List<Pet> pets) async {
    await _prefs.setString(
      _keyPets,
      jsonEncode(pets.map((p) => p.toJson()).toList()),
    );
  }

  // ============================================
  // 健康记录
  // ============================================

  Future<List<HealthRecord>> getHealthRecords(String petId) async {
    await init();
    final json = _prefs.getString(_keyHealthRecords);
    if (json == null) return [];

    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => HealthRecord.fromJson(e))
        .where((r) => r.petId == petId)
        .toList()
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));
  }

  Future<List<HealthRecord>> getWeightRecords(String petId) async {
    final records = await getHealthRecords(petId);
    return records
        .where((r) => r.recordType == HealthRecordType.weight)
        .toList()
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));
  }

  Future<HealthRecord> createHealthRecord(HealthRecord record) async {
    await init();
    final newRecord = HealthRecord(
      id: _generateId(),
      petId: record.petId,
      recordType: record.recordType,
      recordDate: record.recordDate,
      value: record.value,
      note: record.note,
      createdAt: DateTime.now(),
    );

    final json = _prefs.getString(_keyHealthRecords);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(newRecord.toJson());
    await _prefs.setString(_keyHealthRecords, jsonEncode(list));

    return newRecord;
  }

  Future<void> deleteHealthRecord(String recordId) async {
    await init();
    final json = _prefs.getString(_keyHealthRecords);
    if (json == null) return;

    final List<dynamic> list = jsonDecode(json);
    list.removeWhere((e) => e['id'] == recordId);
    await _prefs.setString(_keyHealthRecords, jsonEncode(list));
  }

  // ============================================
  // 提醒
  // ============================================

  Future<List<Reminder>> getReminders(String petId) async {
    await init();
    final json = _prefs.getString(_keyReminders);
    if (json == null) return [];

    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => Reminder.fromJson(e))
        .where((r) => r.petId == petId)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  Future<Reminder> createReminder(Reminder reminder) async {
    await init();
    final newReminder = Reminder(
      id: _generateId(),
      petId: reminder.petId,
      title: reminder.title,
      reminderType: reminder.reminderType,
      scheduledAt: reminder.scheduledAt,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    final json = _prefs.getString(_keyReminders);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(newReminder.toJson());
    await _prefs.setString(_keyReminders, jsonEncode(list));

    return newReminder;
  }

  Future<void> toggleReminderComplete(String reminderId, bool isCompleted) async {
    await init();
    final json = _prefs.getString(_keyReminders);
    if (json == null) return;

    final List<dynamic> list = jsonDecode(json);
    final index = list.indexWhere((e) => e['id'] == reminderId);
    if (index != -1) {
      list[index]['is_completed'] = isCompleted;
      await _prefs.setString(_keyReminders, jsonEncode(list));
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    await init();
    final json = _prefs.getString(_keyReminders);
    if (json == null) return;

    final List<dynamic> list = jsonDecode(json);
    list.removeWhere((e) => e['id'] == reminderId);
    await _prefs.setString(_keyReminders, jsonEncode(list));
  }

  // ============================================
  // AI 分析会话
  // ============================================

  Future<List<AIAnalysisSession>> getAIAnalysisSessions(String petId) async {
    await init();
    final json = _prefs.getString(_keyAIAnalysisSessions);
    if (json == null) return [];

    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => AIAnalysisSession.fromJson(e))
        .where((s) => s.petId == petId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<AIAnalysisSession> createAIAnalysisSession(AIAnalysisSession session) async {
    await init();
    final newSession = AIAnalysisSession(
      id: _generateId(),
      petId: session.petId,
      symptoms: session.symptoms,
      bodyPart: session.bodyPart,
      imageUrl: session.imageUrl,
      analysisResult: session.analysisResult,
      createdAt: DateTime.now(),
    );

    final json = _prefs.getString(_keyAIAnalysisSessions);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(newSession.toJson());
    await _prefs.setString(_keyAIAnalysisSessions, jsonEncode(list));

    return newSession;
  }

  // ============================================
  // 论坛帖子
  // ============================================

  Future<List<ForumPost>> getForumPosts({ForumCategory? category}) async {
    await init();
    final json = _prefs.getString(_keyForumPosts);

    // 如果没有数据，返回模拟数据
    if (json == null) {
      return _getSeedForumPosts();
    }

    final List<dynamic> list = jsonDecode(json);
    var posts = list.map((e) => ForumPost.fromJson(e)).toList();

    if (category != null) {
      posts = posts.where((p) => p.category == category).toList();
    }

    return posts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<ForumPost> createForumPost(ForumPost post) async {
    await init();
    final user = await getCurrentUser();

    final newPost = ForumPost(
      id: _generateId(),
      userId: user?.id ?? 'anonymous',
      authorName: post.authorName,
      authorAvatar: post.authorAvatar,
      title: post.title,
      content: post.content,
      category: post.category,
      likesCount: 0,
      commentsCount: 0,
      createdAt: DateTime.now(),
    );

    final posts = await getForumPosts();
    final allPosts = [newPost, ...posts];
    await _prefs.setString(
      _keyForumPosts,
      jsonEncode(allPosts.map((p) => p.toJson()).toList()),
    );

    return newPost;
  }

  Future<void> toggleLike(String postId) async {
    await init();
    final json = _prefs.getString(_keyForumPosts);
    if (json == null) return;

    final List<dynamic> list = jsonDecode(json);
    final index = list.indexWhere((e) => e['id'] == postId);
    if (index != -1) {
      list[index]['likes_count'] = (list[index]['likes_count'] ?? 0) + 1;
      await _prefs.setString(_keyForumPosts, jsonEncode(list));
    }
  }

  // ============================================
  // 收藏卡牌
  // ============================================

  Future<List<CollectibleCard>> getCollectibleCards(String petId) async {
    await init();
    final json = _prefs.getString(_keyCollectibleCards);
    if (json == null) return [];

    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => CollectibleCard.fromJson(e))
        .where((c) => c.petId == petId)
        .toList()
      ..sort((a, b) => b.obtainedAt.compareTo(a.obtainedAt));
  }

  Future<CollectibleCard> createCollectibleCard(CollectibleCard card) async {
    await init();
    final newCard = CollectibleCard(
      id: _generateId(),
      petId: card.petId,
      name: card.name,
      imageUrl: card.imageUrl,
      description: card.description,
      rarity: card.rarity,
      theme: card.theme,
      tags: card.tags,
      obtainedAt: DateTime.now(),
    );

    final json = _prefs.getString(_keyCollectibleCards);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(newCard.toJson());
    await _prefs.setString(_keyCollectibleCards, jsonEncode(list));

    return newCard;
  }

  // ============================================
  // 图片存储（Base64）
  // ============================================

  Future<String> saveImageLocally(String key, Uint8List bytes) async {
    await init();
    final base64 = base64Encode(bytes);
    final dataUrl = 'data:image/jpeg;base64,$base64';
    await _prefs.setString('image_$key', dataUrl);
    return dataUrl;
  }

  Future<String?> getLocalImage(String key) async {
    await init();
    return _prefs.getString('image_$key');
  }

  // ============================================
  // 工具方法
  // ============================================

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        '_${(1000 + (DateTime.now().microsecond % 9000))}';
  }

  /// 清除所有本地数据
  Future<void> clearAll() async {
    await init();
    await _prefs.clear();
  }

  /// 初始化模拟论坛数据
  List<ForumPost> _getSeedForumPosts() {
    return [
      ForumPost(
        id: 'seed_1',
        userId: 'system',
        authorName: 'Sarah & Bella',
        authorAvatar: '🐕',
        title: 'Tips for thunderstorms?',
        content: "My dog gets super anxious when it rains. Thundershirts haven't worked well. Any natural remedies?",
        category: ForumCategory.question,
        likesCount: 12,
        commentsCount: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ForumPost(
        id: 'seed_2',
        userId: 'system',
        authorName: 'Mike & Whiskers',
        authorAvatar: '🐈',
        title: 'Found a great new grain-free food!',
        content: "Just wanted to share that 'PurePaws' salmon recipe has been great for Whiskers' skin issues.",
        category: ForumCategory.tip,
        likesCount: 24,
        commentsCount: 5,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ForumPost(
        id: 'seed_3',
        userId: 'system',
        authorName: 'Vet Dr. Emily',
        authorAvatar: '👩‍⚕️',
        title: 'Reminder: Tick season is starting',
        content: 'Please remember to check your pets after walks in tall grass! We have seen 3 cases this week already.',
        category: ForumCategory.emergency,
        likesCount: 89,
        commentsCount: 12,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }
}

/// 本地用户模型
class LocalUser {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;

  const LocalUser({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  factory LocalUser.fromJson(Map<String, dynamic> json) {
    return LocalUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}