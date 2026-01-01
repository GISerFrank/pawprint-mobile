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
  static const String _keyForumComments = 'local_forum_comments';
  static const String _keyCollectibleCards = 'local_collectible_cards';
  static const String _keyIllnessRecords = 'local_illness_records';
  static const String _keyMedications = 'local_medications';
  static const String _keyMedicationLogs = 'local_medication_logs';
  static const String _keyDailySymptomLogs = 'local_daily_symptom_logs';
  static const String _keyCareMetrics = 'local_care_metrics';
  static const String _keyMetricLogs = 'local_metric_logs';

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

    try {
      final List<dynamic> list = jsonDecode(json);
      return list
          .map((e) => Pet.fromJson(e as Map<String, dynamic>))
          .where((p) => p.userId == user.id)
          .toList();
    } catch (e) {
      print('Error parsing pets: $e');
      await _prefs.remove(_keyPets);
      return [];
    }
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

    // 处理 id_card
    PetIDCard? idCard = oldPet.idCard;
    if (updates.containsKey('id_card')) {
      final idCardData = updates['id_card'];
      if (idCardData == null) {
        idCard = null;
      } else if (idCardData is Map<String, dynamic>) {
        idCard = PetIDCard.fromJson(idCardData);
      }
    }

    // 处理 collection
    List<CollectibleCard>? collection = oldPet.collection;
    if (updates.containsKey('collection')) {
      final collectionData = updates['collection'];
      if (collectionData == null) {
        collection = null;
      } else if (collectionData is List) {
        collection = collectionData
            .map((e) => e is CollectibleCard
                ? e
                : CollectibleCard.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    final updatedPet = Pet(
      id: oldPet.id,
      userId: oldPet.userId,
      name: updates['name'] ?? oldPet.name,
      species: updates['species'] != null
          ? PetSpecies.fromString(updates['species'])
          : oldPet.species,
      breed: updates['breed'] ?? oldPet.breed,
      birthday: updates['birthday'] != null
          ? DateTime.parse(updates['birthday'])
          : (updates.containsKey('birthday') ? null : oldPet.birthday),
      gotchaDay: updates['gotcha_day'] != null
          ? DateTime.parse(updates['gotcha_day'])
          : (updates.containsKey('gotcha_day') ? null : oldPet.gotchaDay),
      gender: updates['gender'] != null
          ? PetGender.fromString(updates['gender'])
          : oldPet.gender,
      weightKg: updates['weight_kg']?.toDouble() ?? oldPet.weightKg,
      weightUnit: updates['weight_unit'] != null
          ? WeightUnit.fromString(updates['weight_unit'])
          : oldPet.weightUnit,
      isNeutered: updates['is_neutered'] ?? oldPet.isNeutered,
      allergies: updates['allergies'] ?? oldPet.allergies,
      avatarUrl: updates['avatar_url'] ?? oldPet.avatarUrl,
      coins: updates['coins'] ?? oldPet.coins,
      healthStatus: updates['health_status'] != null
          ? HealthStatus.fromString(updates['health_status'])
          : oldPet.healthStatus,
      currentIllnessId: updates.containsKey('current_illness_id')
          ? updates['current_illness_id']
          : oldPet.currentIllnessId,
      createdAt: oldPet.createdAt,
      updatedAt: DateTime.now(),
      idCard: idCard,
      collection: collection,
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

  /// 更新宠物金币（updateCoins 的别名）
  Future<void> updatePetCoins(String petId, int coins) async {
    await updateCoins(petId, coins);
  }

  Future<void> updatePetCollection(
      String petId, List<CollectibleCard> collection) async {
    final pets = await _getAllPets();
    final index = pets.indexWhere((p) => p.id == petId);
    if (index == -1) throw Exception('Pet not found');

    final oldPet = pets[index];
    final updatedPet = oldPet.copyWith(collection: collection);
    pets[index] = updatedPet;
    await _savePets(pets);
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

    try {
      final List<dynamic> list = jsonDecode(json);
      return list
          .map((e) => HealthRecord.fromJson(e as Map<String, dynamic>))
          .where((r) => r.petId == petId)
          .toList()
        ..sort((a, b) => b.recordDate.compareTo(a.recordDate));
    } catch (e) {
      print('Error parsing health records: $e');
      await _prefs.remove(_keyHealthRecords);
      return [];
    }
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

    try {
      final List<dynamic> list = jsonDecode(json);
      return list
          .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
          .where((r) => r.petId == petId)
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    } catch (e) {
      // 如果解析失败，清除损坏的数据并返回空列表
      print('Error parsing reminders: $e');
      await _prefs.remove(_keyReminders);
      return [];
    }
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

  Future<void> toggleReminderComplete(
      String reminderId, bool isCompleted) async {
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

    try {
      final List<dynamic> list = jsonDecode(json);
      return list
          .map((e) => AIAnalysisSession.fromJson(e as Map<String, dynamic>))
          .where((s) => s.petId == petId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error parsing AI sessions: $e');
      await _prefs.remove(_keyAIAnalysisSessions);
      return [];
    }
  }

  Future<AIAnalysisSession> createAIAnalysisSession(
      AIAnalysisSession session) async {
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

    try {
      final List<dynamic> list = jsonDecode(json);
      var posts = list
          .map((e) => ForumPost.fromJson(e as Map<String, dynamic>))
          .toList();

      if (category != null) {
        posts = posts.where((p) => p.category == category).toList();
      }

      return posts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error parsing forum posts: $e');
      await _prefs.remove(_keyForumPosts);
      return _getSeedForumPosts();
    }
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

  Future<List<ForumComment>> getForumComments(String postId) async {
    await init();
    final json = _prefs.getString(_keyForumComments);

    // 如果没有评论数据，返回种子评论
    if (json == null) {
      return _getSeedComments(postId);
    }

    final List<dynamic> list = jsonDecode(json);
    final comments = list
        .map((e) => ForumComment.fromJson(e))
        .where((c) => c.postId == postId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 如果该帖子没有评论，检查是否是种子帖子
    if (comments.isEmpty && postId.startsWith('seed_')) {
      return _getSeedComments(postId);
    }

    return comments;
  }

  Future<ForumComment> createForumComment(ForumComment comment) async {
    await init();
    final user = await getCurrentUser();

    final newComment = ForumComment(
      id: _generateId(),
      postId: comment.postId,
      userId: user?.id ?? 'anonymous',
      authorName: comment.authorName,
      content: comment.content,
      createdAt: DateTime.now(),
    );

    // 保存评论
    final json = _prefs.getString(_keyForumComments);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(newComment.toJson());
    await _prefs.setString(_keyForumComments, jsonEncode(list));

    // 更新帖子的评论数
    final postsJson = _prefs.getString(_keyForumPosts);
    if (postsJson != null) {
      final List<dynamic> posts = jsonDecode(postsJson);
      final index = posts.indexWhere((e) => e['id'] == comment.postId);
      if (index != -1) {
        posts[index]['comments_count'] =
            (posts[index]['comments_count'] ?? 0) + 1;
        await _prefs.setString(_keyForumPosts, jsonEncode(posts));
      }
    }

    return newComment;
  }

  Future<void> deleteForumPost(String postId) async {
    await init();
    final json = _prefs.getString(_keyForumPosts);
    if (json == null) return;

    final List<dynamic> list = jsonDecode(json);
    list.removeWhere((e) => e['id'] == postId);
    await _prefs.setString(_keyForumPosts, jsonEncode(list));

    // 同时删除该帖子的所有评论
    final commentsJson = _prefs.getString(_keyForumComments);
    if (commentsJson != null) {
      final List<dynamic> comments = jsonDecode(commentsJson);
      comments.removeWhere((e) => e['post_id'] == postId);
      await _prefs.setString(_keyForumComments, jsonEncode(comments));
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
        content:
            "My dog gets super anxious when it rains. Thundershirts haven't worked well. Any natural remedies?",
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
        content:
            "Just wanted to share that 'PurePaws' salmon recipe has been great for Whiskers' skin issues.",
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
        content:
            'Please remember to check your pets after walks in tall grass! We have seen 3 cases this week already.',
        category: ForumCategory.emergency,
        likesCount: 89,
        commentsCount: 12,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }

  /// 获取种子评论
  List<ForumComment> _getSeedComments(String postId) {
    final seedComments = <String, List<ForumComment>>{
      'seed_1': [
        ForumComment(
          id: 'comment_1_1',
          postId: 'seed_1',
          userId: 'system',
          authorName: 'Mark',
          content:
              'Have you tried playing calming music? It works wonders for my golden retriever!',
          createdAt: DateTime.now().subtract(const Duration(hours: 20)),
        ),
        ForumComment(
          id: 'comment_1_2',
          postId: 'seed_1',
          userId: 'system',
          authorName: 'Jenny',
          content: 'CBD treats helped my anxious pup. Ask your vet about it.',
          createdAt: DateTime.now().subtract(const Duration(hours: 18)),
        ),
        ForumComment(
          id: 'comment_1_3',
          postId: 'seed_1',
          userId: 'system',
          authorName: 'Tom',
          content:
              'Creating a safe den space with blankets really helps during storms.',
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ],
      'seed_2': [
        ForumComment(
          id: 'comment_2_1',
          postId: 'seed_2',
          userId: 'system',
          authorName: 'Lisa',
          content: 'Thanks for sharing! Where do you buy it?',
          createdAt:
              DateTime.now().subtract(const Duration(days: 1, hours: 20)),
        ),
        ForumComment(
          id: 'comment_2_2',
          postId: 'seed_2',
          userId: 'system',
          authorName: 'Mike & Whiskers',
          content: 'I get it at PetSmart! They usually have good deals.',
          createdAt:
              DateTime.now().subtract(const Duration(days: 1, hours: 18)),
        ),
        ForumComment(
          id: 'comment_2_3',
          postId: 'seed_2',
          userId: 'system',
          authorName: 'Alex',
          content: 'My cat loved it too! Great recommendation.',
          createdAt:
              DateTime.now().subtract(const Duration(days: 1, hours: 10)),
        ),
      ],
      'seed_3': [
        ForumComment(
          id: 'comment_3_1',
          postId: 'seed_3',
          userId: 'system',
          authorName: 'Pet Parent',
          content:
              'Thank you Dr. Emily! Found one on my dog yesterday after a hike.',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        ForumComment(
          id: 'comment_3_2',
          postId: 'seed_3',
          userId: 'system',
          authorName: 'Sarah',
          content:
              'What preventative do you recommend? Currently using Frontline.',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        ForumComment(
          id: 'comment_3_3',
          postId: 'seed_3',
          userId: 'system',
          authorName: 'Vet Dr. Emily',
          content:
              'Frontline is good! Bravecto and NexGard are also excellent options. Consult with your local vet for the best choice.',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ],
    };

    return seedComments[postId] ?? [];
  }

  // ============================================
  // 生病记录
  // ============================================

  Future<List<IllnessRecord>> getIllnessRecords(String petId) async {
    await init();
    final json = _prefs.getString(_keyIllnessRecords);
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => IllnessRecord.fromJson(e))
        .where((r) => r.petId == petId)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  Future<IllnessRecord?> getIllnessRecord(String illnessId) async {
    await init();
    final json = _prefs.getString(_keyIllnessRecords);
    if (json == null) return null;
    final List<dynamic> list = jsonDecode(json);
    try {
      final data = list.firstWhere((e) => e['id'] == illnessId);
      return IllnessRecord.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<IllnessRecord> createIllnessRecord(IllnessRecord record) async {
    await init();
    final newRecord = IllnessRecord(
      id: _generateId(),
      petId: record.petId,
      startDate: record.startDate,
      endDate: record.endDate,
      sickType: record.sickType,
      symptoms: record.symptoms,
      diagnosis: record.diagnosis,
      vetNotes: record.vetNotes,
      followUpDate: record.followUpDate,
      recoveryNote: record.recoveryNote,
      createdAt: DateTime.now(),
    );
    final json = _prefs.getString(_keyIllnessRecords);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(newRecord.toJson());
    await _prefs.setString(_keyIllnessRecords, jsonEncode(list));
    return newRecord;
  }

  Future<void> updateIllnessRecord(
      String illnessId, Map<String, dynamic> updates) async {
    await init();
    final json = _prefs.getString(_keyIllnessRecords);
    if (json == null) return;
    final List<dynamic> list = jsonDecode(json);
    final index = list.indexWhere((e) => e['id'] == illnessId);
    if (index != -1) {
      updates.forEach((key, value) {
        list[index][key] = value;
      });
      await _prefs.setString(_keyIllnessRecords, jsonEncode(list));
    }
  }

  // ============================================
  // 用药记录
  // ============================================

  Future<List<Medication>> getMedications(String illnessId) async {
    await init();
    final json = _prefs.getString(_keyMedications);
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => Medication.fromJson(e))
        .where((m) => m.illnessId == illnessId)
        .toList();
  }

  Future<Medication> createMedication(Medication medication) async {
    await init();
    final newMed = Medication(
      id: _generateId(),
      illnessId: medication.illnessId,
      petId: medication.petId,
      name: medication.name,
      dosage: medication.dosage,
      frequency: medication.frequency,
      timesPerDay: medication.timesPerDay,
      startDate: medication.startDate,
      endDate: medication.endDate,
      createdAt: DateTime.now(),
    );
    final json = _prefs.getString(_keyMedications);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(newMed.toJson());
    await _prefs.setString(_keyMedications, jsonEncode(list));
    return newMed;
  }

  Future<void> deleteMedication(String medicationId) async {
    await init();
    final json = _prefs.getString(_keyMedications);
    if (json == null) return;
    final List<dynamic> list = jsonDecode(json);
    list.removeWhere((e) => e['id'] == medicationId);
    await _prefs.setString(_keyMedications, jsonEncode(list));
  }

  // ============================================
  // 用药打卡记录
  // ============================================

  Future<List<MedicationLog>> getMedicationLogs(
      String petId, DateTime start, DateTime end) async {
    await init();
    final json = _prefs.getString(_keyMedicationLogs);
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => MedicationLog.fromJson(e))
        .where((log) =>
            log.petId == petId &&
            log.scheduledTime.isAfter(start) &&
            log.scheduledTime.isBefore(end))
        .toList();
  }

  Future<MedicationLog> createMedicationLog(MedicationLog log) async {
    await init();
    final newLog = MedicationLog(
      id: _generateId(),
      medicationId: log.medicationId,
      petId: log.petId,
      scheduledTime: log.scheduledTime,
      takenTime: log.takenTime,
      isTaken: log.isTaken,
      isSkipped: log.isSkipped,
      note: log.note,
      createdAt: DateTime.now(),
    );
    final json = _prefs.getString(_keyMedicationLogs);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(newLog.toJson());
    await _prefs.setString(_keyMedicationLogs, jsonEncode(list));
    return newLog;
  }

  // ============================================
  // 每日症状追踪
  // ============================================

  Future<List<DailySymptomLog>> getDailySymptomLogs(String illnessId) async {
    await init();
    final json = _prefs.getString(_keyDailySymptomLogs);
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => DailySymptomLog.fromJson(e))
        .where((log) => log.illnessId == illnessId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<DailySymptomLog> createDailySymptomLog(DailySymptomLog log) async {
    await init();
    // 检查今天是否已经记录过
    final existing = await getDailySymptomLogs(log.illnessId);
    final today = DateTime(log.date.year, log.date.month, log.date.day);
    final existingToday = existing.where((l) {
      final logDate = DateTime(l.date.year, l.date.month, l.date.day);
      return logDate.isAtSameMomentAs(today);
    }).toList();

    if (existingToday.isNotEmpty) {
      final json = _prefs.getString(_keyDailySymptomLogs);
      final List<dynamic> list = json != null ? jsonDecode(json) : [];
      final index = list.indexWhere((e) => e['id'] == existingToday.first.id);
      if (index != -1) {
        list[index]['level'] = log.level.displayName;
        list[index]['note'] = log.note;
        await _prefs.setString(_keyDailySymptomLogs, jsonEncode(list));
        return log.copyWith(id: existingToday.first.id);
      }
    }

    final newLog = DailySymptomLog(
      id: _generateId(),
      illnessId: log.illnessId,
      petId: log.petId,
      date: log.date,
      level: log.level,
      note: log.note,
      createdAt: DateTime.now(),
    );
    final json = _prefs.getString(_keyDailySymptomLogs);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(newLog.toJson());
    await _prefs.setString(_keyDailySymptomLogs, jsonEncode(list));
    return newLog;
  }

  // ============================================
  // Diet - Feeding Logs
  // ============================================

  static const String _keyFeedingLogs = 'local_feeding_logs';
  static const String _keyWaterLogs = 'local_water_logs';

  Future<List<FeedingLog>> getFeedingLogs(
      String petId, DateTime start, DateTime end) async {
    await init();
    final json = _prefs.getString(_keyFeedingLogs);
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => FeedingLog.fromJson(e))
        .where((r) =>
            r.petId == petId &&
            r.feedingTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
            r.feedingTime.isBefore(end))
        .toList()
      ..sort((a, b) => b.feedingTime.compareTo(a.feedingTime));
  }

  Future<FeedingLog> createFeedingLog(FeedingLog log) async {
    await init();
    final newLog = FeedingLog(
      id: 'feeding_${DateTime.now().millisecondsSinceEpoch}',
      petId: log.petId,
      mealType: log.mealType,
      foodType: log.foodType,
      foodName: log.foodName,
      amount: log.amount,
      note: log.note,
      feedingTime: log.feedingTime,
      createdAt: DateTime.now(),
    );
    final json = _prefs.getString(_keyFeedingLogs);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(newLog.toJson());
    await _prefs.setString(_keyFeedingLogs, jsonEncode(list));
    return newLog;
  }

  Future<void> deleteFeedingLog(String logId) async {
    await init();
    final json = _prefs.getString(_keyFeedingLogs);
    if (json == null) return;
    final List<dynamic> list = jsonDecode(json);
    list.removeWhere((e) => e['id'] == logId);
    await _prefs.setString(_keyFeedingLogs, jsonEncode(list));
  }

  // ============================================
  // Diet - Water Logs
  // ============================================

  Future<List<WaterLog>> getWaterLogs(
      String petId, DateTime start, DateTime end) async {
    await init();
    final json = _prefs.getString(_keyWaterLogs);
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => WaterLog.fromJson(e))
        .where((r) =>
            r.petId == petId &&
            r.logTime.isAfter(start.subtract(const Duration(seconds: 1))) &&
            r.logTime.isBefore(end))
        .toList()
      ..sort((a, b) => b.logTime.compareTo(a.logTime));
  }

  Future<WaterLog> createWaterLog(WaterLog log) async {
    await init();
    final newLog = WaterLog(
      id: 'water_${DateTime.now().millisecondsSinceEpoch}',
      petId: log.petId,
      amount: log.amount,
      logTime: log.logTime,
      createdAt: DateTime.now(),
    );
    final json = _prefs.getString(_keyWaterLogs);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(newLog.toJson());
    await _prefs.setString(_keyWaterLogs, jsonEncode(list));
    return newLog;
  }

  // ============================================
  // Activity Logs
  // ============================================

  static const String _keyActivityLogs = 'local_activity_logs';

  Future<List<ActivityLog>> getActivityLogs(
      String petId, DateTime start, DateTime end) async {
    await init();
    final json = _prefs.getString(_keyActivityLogs);
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => ActivityLog.fromJson(e))
        .where((r) =>
            r.petId == petId &&
            r.activityTime
                .isAfter(start.subtract(const Duration(seconds: 1))) &&
            r.activityTime.isBefore(end))
        .toList()
      ..sort((a, b) => b.activityTime.compareTo(a.activityTime));
  }

  Future<ActivityLog> createActivityLog(ActivityLog log) async {
    await init();
    final newLog = ActivityLog(
      id: 'activity_${DateTime.now().millisecondsSinceEpoch}',
      petId: log.petId,
      activityType: log.activityType,
      intensity: log.intensity,
      durationMinutes: log.durationMinutes,
      distanceKm: log.distanceKm,
      note: log.note,
      activityTime: log.activityTime,
      createdAt: DateTime.now(),
    );
    final json = _prefs.getString(_keyActivityLogs);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(newLog.toJson());
    await _prefs.setString(_keyActivityLogs, jsonEncode(list));
    return newLog;
  }

  Future<void> deleteActivityLog(String logId) async {
    await init();
    final json = _prefs.getString(_keyActivityLogs);
    if (json == null) return;
    final List<dynamic> list = jsonDecode(json);
    list.removeWhere((e) => e['id'] == logId);
    await _prefs.setString(_keyActivityLogs, jsonEncode(list));
  }

  // ============================================
  // Care Metrics
  // ============================================

  Future<List<CareMetric>> getCareMetrics(String petId) async {
    await init();
    final json = _prefs.getString(_keyCareMetrics);
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => CareMetric.fromJson(e))
        .where((m) => m.petId == petId)
        .toList();
  }

  Future<CareMetric?> getCareMetric(String metricId) async {
    await init();
    final json = _prefs.getString(_keyCareMetrics);
    if (json == null) return null;
    final List<dynamic> list = jsonDecode(json);
    try {
      final found = list.firstWhere((e) => e['id'] == metricId);
      return CareMetric.fromJson(found);
    } catch (_) {
      return null;
    }
  }

  Future<CareMetric> createCareMetric(CareMetric metric) async {
    await init();
    final json = _prefs.getString(_keyCareMetrics);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(metric.toJson());
    await _prefs.setString(_keyCareMetrics, jsonEncode(list));
    return metric;
  }

  Future<void> updateCareMetric(
      String metricId, Map<String, dynamic> updates) async {
    await init();
    final json = _prefs.getString(_keyCareMetrics);
    if (json == null) return;
    final List<dynamic> list = jsonDecode(json);
    final index = list.indexWhere((e) => e['id'] == metricId);
    if (index != -1) {
      list[index] = {...list[index], ...updates};
      await _prefs.setString(_keyCareMetrics, jsonEncode(list));
    }
  }

  Future<void> deleteCareMetric(String metricId) async {
    await init();
    final json = _prefs.getString(_keyCareMetrics);
    if (json == null) return;
    final List<dynamic> list = jsonDecode(json);
    list.removeWhere((e) => e['id'] == metricId);
    await _prefs.setString(_keyCareMetrics, jsonEncode(list));
  }

  // ============================================
  // Metric Logs
  // ============================================

  Future<List<MetricLog>> getMetricLogs(
      String petId, DateTime start, DateTime end) async {
    await init();
    final json = _prefs.getString(_keyMetricLogs);
    if (json == null) return [];
    final List<dynamic> list = jsonDecode(json);
    return list
        .map((e) => MetricLog.fromJson(e))
        .where((l) =>
            l.petId == petId &&
            l.loggedAt.isAfter(start) &&
            l.loggedAt.isBefore(end))
        .toList();
  }

  Future<MetricLog> createMetricLog(MetricLog log) async {
    await init();
    final json = _prefs.getString(_keyMetricLogs);
    final List<dynamic> list = json != null ? jsonDecode(json) : [];
    list.add(log.toJson());
    await _prefs.setString(_keyMetricLogs, jsonEncode(list));
    return log;
  }

  Future<void> deleteMetricLog(String logId) async {
    await init();
    final json = _prefs.getString(_keyMetricLogs);
    if (json == null) return;
    final List<dynamic> list = jsonDecode(json);
    list.removeWhere((e) => e['id'] == logId);
    await _prefs.setString(_keyMetricLogs, jsonEncode(list));
  }

  // ============================================
  // Pinned Metrics (Quick Log on Care Page)
  // ============================================

  static const String _keyPinnedMetrics = 'local_pinned_metrics';

  /// 获取用户 pin 的指标 ID 列表
  Future<List<String>> getPinnedMetricIds(String petId) async {
    await init();
    final json = _prefs.getString(_keyPinnedMetrics);
    if (json == null) return [];
    final Map<String, dynamic> data = jsonDecode(json);
    final List<dynamic> ids = data[petId] ?? [];
    return ids.cast<String>();
  }

  /// 添加 pinned metric
  Future<void> addPinnedMetric(String petId, String metricId) async {
    await init();
    final json = _prefs.getString(_keyPinnedMetrics);
    final Map<String, dynamic> data = json != null ? jsonDecode(json) : {};
    final List<dynamic> ids = data[petId] ?? [];
    if (!ids.contains(metricId)) {
      ids.add(metricId);
      data[petId] = ids;
      await _prefs.setString(_keyPinnedMetrics, jsonEncode(data));
    }
  }

  /// 移除 pinned metric
  Future<void> removePinnedMetric(String petId, String metricId) async {
    await init();
    final json = _prefs.getString(_keyPinnedMetrics);
    if (json == null) return;
    final Map<String, dynamic> data = jsonDecode(json);
    final List<dynamic> ids = data[petId] ?? [];
    ids.remove(metricId);
    data[petId] = ids;
    await _prefs.setString(_keyPinnedMetrics, jsonEncode(data));
  }

  /// 检查指标是否已 pin
  Future<bool> isMetricPinned(String petId, String metricId) async {
    final ids = await getPinnedMetricIds(petId);
    return ids.contains(metricId);
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
