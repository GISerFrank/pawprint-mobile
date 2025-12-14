import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

/// Supabase 数据库服务
class DatabaseService {
  final SupabaseClient _client;

  DatabaseService(this._client);

  // ============================================
  // Pet Operations
  // ============================================

  /// 获取当前用户的所有宠物
  Future<List<Pet>> getPets() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('pets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Pet.fromJson(json)).toList();
  }

  /// 获取单个宠物详情（包含关联数据）
  Future<Pet?> getPetById(String petId) async {
    final response = await _client
        .from('pets')
        .select()
        .eq('id', petId)
        .single();

    final pet = Pet.fromJson(response);

    // 加载身体部位图片
    final bodyImages = await getPetBodyImages(petId);
    final bodyImageMap = <BodyPart, String?>{};
    for (final img in bodyImages) {
      bodyImageMap[img.bodyPart] = img.imageUrl;
    }

    // 加载 ID 卡片
    final idCard = await getPetIDCard(petId);

    // 加载收藏卡牌
    final collection = await getCollectibleCards(petId);

    return pet.copyWith(
      bodyPartImages: bodyImageMap,
      idCard: idCard,
      collection: collection,
    );
  }

  /// 创建新宠物
  Future<Pet> createPet(Pet pet) async {
    final response = await _client
        .from('pets')
        .insert(pet.toInsertJson())
        .select()
        .single();

    return Pet.fromJson(response);
  }

  /// 更新宠物信息
  Future<Pet> updatePet(String petId, Map<String, dynamic> updates) async {
    final response = await _client
        .from('pets')
        .update(updates)
        .eq('id', petId)
        .select()
        .single();

    return Pet.fromJson(response);
  }

  /// 删除宠物
  Future<void> deletePet(String petId) async {
    await _client.from('pets').delete().eq('id', petId);
  }

  /// 更新宠物金币
  Future<void> updateCoins(String petId, int coins) async {
    await _client.from('pets').update({'coins': coins}).eq('id', petId);
  }

  // ============================================
  // Pet Body Images
  // ============================================

  Future<List<PetBodyImage>> getPetBodyImages(String petId) async {
    final response = await _client
        .from('pet_body_images')
        .select()
        .eq('pet_id', petId);

    return (response as List).map((json) => PetBodyImage.fromJson(json)).toList();
  }

  Future<PetBodyImage> upsertPetBodyImage({
    required String petId,
    required BodyPart bodyPart,
    required String imageUrl,
  }) async {
    final response = await _client
        .from('pet_body_images')
        .upsert({
      'pet_id': petId,
      'body_part': bodyPart.displayName,
      'image_url': imageUrl,
    }, onConflict: 'pet_id,body_part')
        .select()
        .single();

    return PetBodyImage.fromJson(response);
  }

  // ============================================
  // Pet ID Cards
  // ============================================

  Future<PetIDCard?> getPetIDCard(String petId) async {
    final response = await _client
        .from('pet_id_cards')
        .select()
        .eq('pet_id', petId)
        .maybeSingle();

    if (response == null) return null;
    return PetIDCard.fromJson(response);
  }

  Future<PetIDCard> createPetIDCard(PetIDCard card) async {
    // 先删除旧的（如果存在）
    await _client.from('pet_id_cards').delete().eq('pet_id', card.petId);

    final response = await _client
        .from('pet_id_cards')
        .insert(card.toJson())
        .select()
        .single();

    return PetIDCard.fromJson(response);
  }

  // ============================================
  // Collectible Cards
  // ============================================

  Future<List<CollectibleCard>> getCollectibleCards(String petId) async {
    final response = await _client
        .from('collectible_cards')
        .select()
        .eq('pet_id', petId)
        .order('obtained_at', ascending: false);

    return (response as List).map((json) => CollectibleCard.fromJson(json)).toList();
  }

  Future<CollectibleCard> createCollectibleCard(CollectibleCard card) async {
    final response = await _client
        .from('collectible_cards')
        .insert(card.toJson())
        .select()
        .single();

    return CollectibleCard.fromJson(response);
  }

  // ============================================
  // Health Records
  // ============================================

  Future<List<HealthRecord>> getHealthRecords(String petId, {int? limit}) async {
    var query = _client
        .from('health_records')
        .select()
        .eq('pet_id', petId)
        .order('record_date', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return (response as List).map((json) => HealthRecord.fromJson(json)).toList();
  }

  Future<List<HealthRecord>> getWeightRecords(String petId) async {
    final response = await _client
        .from('health_records')
        .select()
        .eq('pet_id', petId)
        .eq('record_type', 'Weight')
        .order('record_date', ascending: true);

    return (response as List).map((json) => HealthRecord.fromJson(json)).toList();
  }

  Future<HealthRecord> createHealthRecord(HealthRecord record) async {
    final response = await _client
        .from('health_records')
        .insert(record.toJson())
        .select()
        .single();

    return HealthRecord.fromJson(response);
  }

  Future<void> deleteHealthRecord(String recordId) async {
    await _client.from('health_records').delete().eq('id', recordId);
  }

  // ============================================
  // Reminders
  // ============================================

  Future<List<Reminder>> getReminders(String petId) async {
    final response = await _client
        .from('reminders')
        .select()
        .eq('pet_id', petId)
        .order('scheduled_at', ascending: true);

    return (response as List).map((json) => Reminder.fromJson(json)).toList();
  }

  Future<Reminder> createReminder(Reminder reminder) async {
    final response = await _client
        .from('reminders')
        .insert(reminder.toJson())
        .select()
        .single();

    return Reminder.fromJson(response);
  }

  Future<Reminder> updateReminder(String reminderId, Map<String, dynamic> updates) async {
    final response = await _client
        .from('reminders')
        .update(updates)
        .eq('id', reminderId)
        .select()
        .single();

    return Reminder.fromJson(response);
  }

  Future<void> toggleReminderComplete(String reminderId, bool isCompleted) async {
    await _client
        .from('reminders')
        .update({'is_completed': isCompleted})
        .eq('id', reminderId);
  }

  Future<void> deleteReminder(String reminderId) async {
    await _client.from('reminders').delete().eq('id', reminderId);
  }

  // ============================================
  // AI Analysis Sessions
  // ============================================

  Future<List<AIAnalysisSession>> getAIAnalysisSessions(String petId) async {
    final response = await _client
        .from('ai_analysis_sessions')
        .select()
        .eq('pet_id', petId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => AIAnalysisSession.fromJson(json)).toList();
  }

  Future<AIAnalysisSession> createAIAnalysisSession(AIAnalysisSession session) async {
    final response = await _client
        .from('ai_analysis_sessions')
        .insert(session.toJson())
        .select()
        .single();

    return AIAnalysisSession.fromJson(response);
  }

  // ============================================
  // Forum Posts
  // ============================================

  Future<List<ForumPost>> getForumPosts({
    ForumCategory? category,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client.from('forum_posts').select();

    // 过滤必须在 order/range 之前
    if (category != null) {
      query = query.eq('category', category.displayName);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) => ForumPost.fromJson(json)).toList();
  }

  Future<ForumPost> createForumPost(ForumPost post) async {
    final response = await _client
        .from('forum_posts')
        .insert(post.toJson())
        .select()
        .single();

    return ForumPost.fromJson(response);
  }

  Future<void> deleteForumPost(String postId) async {
    await _client.from('forum_posts').delete().eq('id', postId);
  }

  // ============================================
  // Forum Comments
  // ============================================

  Future<List<ForumComment>> getForumComments(String postId) async {
    final response = await _client
        .from('forum_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => ForumComment.fromJson(json)).toList();
  }

  Future<ForumComment> createForumComment(ForumComment comment) async {
    final response = await _client
        .from('forum_comments')
        .insert(comment.toJson())
        .select()
        .single();

    return ForumComment.fromJson(response);
  }

  // ============================================
  // Forum Likes
  // ============================================

  Future<bool> hasUserLikedPost(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('forum_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    return response != null;
  }

  Future<void> toggleLike(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final existing = await _client
        .from('forum_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('forum_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } else {
      await _client.from('forum_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }
}