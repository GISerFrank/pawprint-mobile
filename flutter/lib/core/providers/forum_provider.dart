import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'service_providers.dart';
import 'auth_provider.dart';
import 'pet_provider.dart';

/// 当前论坛分类过滤
final forumCategoryFilterProvider = StateProvider<ForumCategory?>((ref) => null);

/// 论坛帖子列表
final forumPostsProvider = FutureProvider<List<ForumPost>>((ref) async {
  final category = ref.watch(forumCategoryFilterProvider);
  final db = ref.watch(databaseServiceProvider);
  
  return db.getForumPosts(category: category);
});

/// 论坛管理 Notifier
class ForumNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _db;
  final Ref _ref;

  ForumNotifier(this._db, this._ref) : super(const AsyncValue.data(null));

  /// 发布帖子
  Future<ForumPost> createPost({
    required String title,
    required String content,
    required ForumCategory category,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('User not authenticated');

    // 获取当前宠物名称作为作者名
    final pet = await _ref.read(currentPetProvider.future);
    final authorName = pet?.name ?? 'Anonymous';

    final post = await _db.createForumPost(ForumPost(
      id: '',
      userId: user.id,
      authorName: authorName,
      authorAvatar: _getAvatarEmoji(pet?.species),
      title: title,
      content: content,
      category: category,
      createdAt: DateTime.now(),
    ));

    _ref.invalidate(forumPostsProvider);
    return post;
  }

  /// 点赞/取消点赞
  Future<void> toggleLike(String postId) async {
    await _db.toggleLike(postId);
    _ref.invalidate(forumPostsProvider);
  }

  /// 添加评论
  Future<ForumComment> addComment({
    required String postId,
    required String content,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('User not authenticated');

    final pet = await _ref.read(currentPetProvider.future);
    final authorName = pet?.name ?? 'Anonymous';

    final comment = await _db.createForumComment(ForumComment(
      id: '',
      postId: postId,
      userId: user.id,
      authorName: authorName,
      content: content,
      createdAt: DateTime.now(),
    ));

    _ref.invalidate(forumPostsProvider);
    return comment;
  }

  /// 删除帖子
  Future<void> deletePost(String postId) async {
    await _db.deleteForumPost(postId);
    _ref.invalidate(forumPostsProvider);
  }

  String? _getAvatarEmoji(PetSpecies? species) {
    if (species == null) return null;
    switch (species) {
      case PetSpecies.dog:
        return '🐕';
      case PetSpecies.cat:
        return '🐈';
      case PetSpecies.bird:
        return '🐦';
      case PetSpecies.rabbit:
        return '🐰';
      case PetSpecies.fish:
        return '🐠';
      case PetSpecies.other:
        return '🐾';
    }
  }
}

/// 论坛管理 Provider
final forumNotifierProvider = StateNotifierProvider<ForumNotifier, AsyncValue<void>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return ForumNotifier(db, ref);
});

/// 获取帖子评论
final postCommentsProvider = FutureProvider.family<List<ForumComment>, String>((ref, postId) async {
  final db = ref.watch(databaseServiceProvider);
  return db.getForumComments(postId);
});

/// 检查用户是否点赞了帖子
final hasLikedPostProvider = FutureProvider.family<bool, String>((ref, postId) async {
  final db = ref.watch(databaseServiceProvider);
  return db.hasUserLikedPost(postId);
});
