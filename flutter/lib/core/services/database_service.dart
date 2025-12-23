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

  // ============================================
  // Illness Records
  // ============================================

  Future<List<IllnessRecord>> getIllnessRecords(String petId) async {
    final response = await _client
        .from('illness_records')
        .select()
        .eq('pet_id', petId)
        .order('start_date', ascending: false);
    return (response as List).map((json) => IllnessRecord.fromJson(json)).toList();
  }

  Future<IllnessRecord?> getIllnessRecord(String illnessId) async {
    final response = await _client
        .from('illness_records')
        .select()
        .eq('id', illnessId)
        .maybeSingle();
    if (response == null) return null;
    return IllnessRecord.fromJson(response);
  }

  Future<IllnessRecord> createIllnessRecord(IllnessRecord record) async {
    final response = await _client
        .from('illness_records')
        .insert({
          'pet_id': record.petId,
          'start_date': record.startDate.toIso8601String(),
          'end_date': record.endDate?.toIso8601String(),
          'sick_type': record.sickType.displayName,
          'symptoms': record.symptoms,
          'diagnosis': record.diagnosis,
          'vet_notes': record.vetNotes,
          'follow_up_date': record.followUpDate?.toIso8601String(),
          'recovery_note': record.recoveryNote,
        })
        .select()
        .single();
    return IllnessRecord.fromJson(response);
  }

  Future<void> updateIllnessRecord(String illnessId, Map<String, dynamic> updates) async {
    await _client
        .from('illness_records')
        .update(updates)
        .eq('id', illnessId);
  }

  // ============================================
  // Medications
  // ============================================

  Future<List<Medication>> getMedications(String illnessId) async {
    final response = await _client
        .from('medications')
        .select()
        .eq('illness_id', illnessId);
    return (response as List).map((json) => Medication.fromJson(json)).toList();
  }

  Future<Medication> createMedication(Medication medication) async {
    final response = await _client
        .from('medications')
        .insert({
          'illness_id': medication.illnessId,
          'pet_id': medication.petId,
          'name': medication.name,
          'dosage': medication.dosage,
          'frequency': medication.frequency,
          'times_per_day': medication.timesPerDay,
          'start_date': medication.startDate.toIso8601String(),
          'end_date': medication.endDate?.toIso8601String(),
        })
        .select()
        .single();
    return Medication.fromJson(response);
  }

  Future<void> deleteMedication(String medicationId) async {
    await _client.from('medications').delete().eq('id', medicationId);
  }

  // ============================================
  // Medication Logs
  // ============================================

  Future<List<MedicationLog>> getMedicationLogs(String petId, DateTime start, DateTime end) async {
    final response = await _client
        .from('medication_logs')
        .select()
        .eq('pet_id', petId)
        .gte('scheduled_time', start.toIso8601String())
        .lt('scheduled_time', end.toIso8601String());
    return (response as List).map((json) => MedicationLog.fromJson(json)).toList();
  }

  Future<MedicationLog> createMedicationLog(MedicationLog log) async {
    final response = await _client
        .from('medication_logs')
        .insert({
          'medication_id': log.medicationId,
          'pet_id': log.petId,
          'scheduled_time': log.scheduledTime.toIso8601String(),
          'taken_time': log.takenTime?.toIso8601String(),
          'is_taken': log.isTaken,
          'is_skipped': log.isSkipped,
          'note': log.note,
        })
        .select()
        .single();
    return MedicationLog.fromJson(response);
  }

  // ============================================
  // Daily Symptom Logs
  // ============================================

  Future<List<DailySymptomLog>> getDailySymptomLogs(String illnessId) async {
    final response = await _client
        .from('daily_symptom_logs')
        .select()
        .eq('illness_id', illnessId)
        .order('date', ascending: true);
    return (response as List).map((json) => DailySymptomLog.fromJson(json)).toList();
  }

  Future<DailySymptomLog> createDailySymptomLog(DailySymptomLog log) async {
    // Check if already logged today - upsert if exists
    final today = DateTime(log.date.year, log.date.month, log.date.day);
    final existing = await _client
        .from('daily_symptom_logs')
        .select()
        .eq('illness_id', log.illnessId)
        .gte('date', today.toIso8601String())
        .lt('date', today.add(const Duration(days: 1)).toIso8601String())
        .maybeSingle();

    if (existing != null) {
      final response = await _client
          .from('daily_symptom_logs')
          .update({'level': log.level.displayName, 'note': log.note})
          .eq('id', existing['id'])
          .select()
          .single();
      return DailySymptomLog.fromJson(response);
    }

    final response = await _client
        .from('daily_symptom_logs')
        .insert({
          'illness_id': log.illnessId,
          'pet_id': log.petId,
          'date': log.date.toIso8601String(),
          'level': log.level.displayName,
          'note': log.note,
        })
        .select()
        .single();
    return DailySymptomLog.fromJson(response);
  }

  // ============================================
  // Feeding Logs
  // ============================================

  Future<List<FeedingLog>> getFeedingLogs(String petId, DateTime start, DateTime end) async {
    final response = await _client
        .from('feeding_logs')
        .select()
        .eq('pet_id', petId)
        .gte('feeding_time', start.toIso8601String())
        .lt('feeding_time', end.toIso8601String())
        .order('feeding_time', ascending: false);
    return (response as List).map((json) => FeedingLog.fromJson(json)).toList();
  }

  Future<FeedingLog> createFeedingLog(FeedingLog log) async {
    final response = await _client
        .from('feeding_logs')
        .insert({
          'pet_id': log.petId,
          'meal_type': log.mealType.displayName,
          'food_type': log.foodType.displayName,
          'food_name': log.foodName,
          'amount': log.amount,
          'note': log.note,
          'feeding_time': log.feedingTime.toIso8601String(),
        })
        .select()
        .single();
    return FeedingLog.fromJson(response);
  }

  Future<void> deleteFeedingLog(String logId) async {
    await _client.from('feeding_logs').delete().eq('id', logId);
  }

  // ============================================
  // Water Logs
  // ============================================

  Future<List<WaterLog>> getWaterLogs(String petId, DateTime start, DateTime end) async {
    final response = await _client
        .from('water_logs')
        .select()
        .eq('pet_id', petId)
        .gte('log_time', start.toIso8601String())
        .lt('log_time', end.toIso8601String())
        .order('log_time', ascending: false);
    return (response as List).map((json) => WaterLog.fromJson(json)).toList();
  }

  Future<WaterLog> createWaterLog(WaterLog log) async {
    final response = await _client
        .from('water_logs')
        .insert({
          'pet_id': log.petId,
          'amount': log.amount,
          'log_time': log.logTime.toIso8601String(),
        })
        .select()
        .single();
    return WaterLog.fromJson(response);
  }

  // ============================================
  // Activity Logs
  // ============================================

  Future<List<ActivityLog>> getActivityLogs(String petId, DateTime start, DateTime end) async {
    final response = await _client
        .from('activity_logs')
        .select()
        .eq('pet_id', petId)
        .gte('activity_time', start.toIso8601String())
        .lt('activity_time', end.toIso8601String())
        .order('activity_time', ascending: false);
    return (response as List).map((json) => ActivityLog.fromJson(json)).toList();
  }

  Future<ActivityLog> createActivityLog(ActivityLog log) async {
    final response = await _client
        .from('activity_logs')
        .insert({
          'pet_id': log.petId,
          'activity_type': log.activityType.displayName,
          'intensity': log.intensity.displayName,
          'duration_minutes': log.durationMinutes,
          'distance_km': log.distanceKm,
          'note': log.note,
          'activity_time': log.activityTime.toIso8601String(),
        })
        .select()
        .single();
    return ActivityLog.fromJson(response);
  }

  Future<void> deleteActivityLog(String logId) async {
    await _client.from('activity_logs').delete().eq('id', logId);
  }

  // ============================================
  // Care Metrics
  // ============================================

  Future<List<CareMetric>> getCareMetrics(String petId) async {
    final response = await _client
        .from('care_metrics')
        .select()
        .eq('pet_id', petId)
        .order('priority', ascending: true);
    return (response as List).map((json) => CareMetric.fromJson(json)).toList();
  }

  Future<CareMetric> createCareMetric(CareMetric metric) async {
    final response = await _client
        .from('care_metrics')
        .insert(metric.toJson())
        .select()
        .single();
    return CareMetric.fromJson(response);
  }

  Future<void> updateCareMetric(String metricId, Map<String, dynamic> updates) async {
    await _client.from('care_metrics').update(updates).eq('id', metricId);
  }

  Future<void> deleteCareMetric(String metricId) async {
    await _client.from('care_metrics').delete().eq('id', metricId);
  }

  // ============================================
  // Metric Logs
  // ============================================

  Future<List<MetricLog>> getMetricLogs(String petId, DateTime start, DateTime end) async {
    final response = await _client
        .from('metric_logs')
        .select()
        .eq('pet_id', petId)
        .gte('logged_at', start.toIso8601String())
        .lt('logged_at', end.toIso8601String())
        .order('logged_at', ascending: false);
    return (response as List).map((json) => MetricLog.fromJson(json)).toList();
  }

  Future<MetricLog> createMetricLog(MetricLog log) async {
    final response = await _client
        .from('metric_logs')
        .insert(log.toJson())
        .select()
        .single();
    return MetricLog.fromJson(response);
  }

  Future<void> deleteMetricLog(String logId) async {
    await _client.from('metric_logs').delete().eq('id', logId);
  }
}