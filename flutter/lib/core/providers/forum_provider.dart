import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/models.dart';
import 'service_providers.dart';
import 'auth_provider.dart';
import 'pet_provider.dart';

/// 当前论坛分类过滤
final forumCategoryFilterProvider =
    StateProvider<ForumCategory?>((ref) => null);

/// 论坛帖子列表
final forumPostsProvider = FutureProvider<List<ForumPost>>((ref) async {
  final category = ref.watch(forumCategoryFilterProvider);

  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageServiceProvider);
    return localStorage.getForumPosts(category: category);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getForumPosts(category: category);
  }
});

/// 论坛管理 Notifier
class ForumNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  ForumNotifier(this._ref) : super(const AsyncValue.data(null));

  /// 发布帖子
  Future<ForumPost> createPost({
    required String title,
    required String content,
    required ForumCategory category,
    String? authorName,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('User not authenticated');

    final pet = await _ref.read(currentPetProvider.future);
    final name = authorName ?? pet?.name ?? 'Anonymous';

    final post = ForumPost(
      id: '',
      userId: user.id,
      authorName: name,
      authorAvatar: _getAvatarEmoji(pet?.species),
      title: title,
      content: content,
      category: category,
      createdAt: DateTime.now(),
    );

    ForumPost createdPost;
    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      createdPost = await localStorage.createForumPost(post);
    } else {
      final db = _ref.read(databaseServiceProvider);
      createdPost = await db.createForumPost(post);
    }

    _ref.invalidate(forumPostsProvider);
    return createdPost;
  }

  /// 点赞/取消点赞
  Future<void> toggleLike(String postId) async {
    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      await localStorage.toggleLike(postId);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.toggleLike(postId);
    }
    _ref.invalidate(forumPostsProvider);
  }

  /// 添加评论
  Future<ForumComment> addComment({
    required String postId,
    required String content,
    String? authorName,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) throw Exception('User not authenticated');

    final pet = await _ref.read(currentPetProvider.future);
    final name = authorName ?? pet?.name ?? 'Anonymous';

    final comment = ForumComment(
      id: '',
      postId: postId,
      userId: user.id,
      authorName: name,
      content: content,
      createdAt: DateTime.now(),
    );

    ForumComment createdComment;
    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      createdComment = await localStorage.createForumComment(comment);
    } else {
      final db = _ref.read(databaseServiceProvider);
      createdComment = await db.createForumComment(comment);
    }

    _ref.invalidate(forumPostsProvider);
    return createdComment;
  }

  /// 删除帖子
  Future<void> deletePost(String postId) async {
    if (AppConfig.useLocalMode) {
      final localStorage = _ref.read(localStorageServiceProvider);
      await localStorage.deleteForumPost(postId);
    } else {
      final db = _ref.read(databaseServiceProvider);
      await db.deleteForumPost(postId);
    }
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
final forumNotifierProvider =
    StateNotifierProvider<ForumNotifier, AsyncValue<void>>((ref) {
  return ForumNotifier(ref);
});

/// 获取帖子评论
final postCommentsProvider =
    FutureProvider.family<List<ForumComment>, String>((ref, postId) async {
  if (AppConfig.useLocalMode) {
    final localStorage = ref.watch(localStorageServiceProvider);
    return localStorage.getForumComments(postId);
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.getForumComments(postId);
  }
});

/// 检查用户是否点赞了帖子
final hasLikedPostProvider =
    FutureProvider.family<bool, String>((ref, postId) async {
  if (AppConfig.useLocalMode) {
    return false; // 本地模式简化处理
  } else {
    final db = ref.watch(databaseServiceProvider);
    return db.hasUserLikedPost(postId);
  }
});
