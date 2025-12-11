import 'package:equatable/equatable.dart';
import 'enums.dart';

/// 论坛帖子模型
class ForumPost extends Equatable {
  final String id;
  final String userId;
  final String authorName;
  final String? authorAvatar;
  final String title;
  final String content;
  final ForumCategory category;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;

  // 关联数据
  final List<ForumComment>? comments;
  final bool? isLikedByUser;

  const ForumPost({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorAvatar,
    required this.title,
    required this.content,
    required this.category,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.createdAt,
    this.comments,
    this.isLikedByUser,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      authorName: json['author_name'] as String,
      authorAvatar: json['author_avatar'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      category: ForumCategory.fromString(json['category'] as String),
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'title': title,
      'content': content,
      'category': category.displayName,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ForumPost copyWith({
    String? id,
    String? userId,
    String? authorName,
    String? authorAvatar,
    String? title,
    String? content,
    ForumCategory? category,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    List<ForumComment>? comments,
    bool? isLikedByUser,
  }) {
    return ForumPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      comments: comments ?? this.comments,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
    );
  }

  /// 是否是当前用户的帖子
  bool isOwnedBy(String currentUserId) => userId == currentUserId;

  @override
  List<Object?> get props => [
    id,
    userId,
    authorName,
    authorAvatar,
    title,
    content,
    category,
    likesCount,
    commentsCount,
    createdAt,
  ];
}

/// 论坛评论模型
class ForumComment extends Equatable {
  final String id;
  final String postId;
  final String userId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const ForumComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  factory ForumComment.fromJson(Map<String, dynamic> json) {
    return ForumComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      authorName: json['author_name'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'author_name': authorName,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 是否是当前用户的评论
  bool isOwnedBy(String currentUserId) => userId == currentUserId;

  @override
  List<Object?> get props => [id, postId, userId, authorName, content, createdAt];
}

/// 点赞记录模型
class ForumLike extends Equatable {
  final String id;
  final String postId;
  final String userId;
  final DateTime createdAt;

  const ForumLike({
    required this.id,
    required this.postId,
    required this.userId,
    required this.createdAt,
  });

  factory ForumLike.fromJson(Map<String, dynamic> json) {
    return ForumLike(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, postId, userId, createdAt];
}