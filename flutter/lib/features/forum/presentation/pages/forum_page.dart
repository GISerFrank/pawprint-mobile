import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/widgets/widgets.dart';

class ForumPage extends ConsumerStatefulWidget {
  const ForumPage({super.key});

  @override
  ConsumerState<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends ConsumerState<ForumPage> {
  String _selectedCategory = 'All';
  String? _expandedPostId;
  final _commentController = TextEditingController();

  final _categories = ['All', 'Question', 'Tip', 'Story', 'Emergency'];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreatePostSheet(
        onPost: (title, content, category) async {
          final user = ref.read(currentUserProvider);
          if (user == null) return;

          await ref.read(forumNotifierProvider.notifier).createPost(
                title: title,
                content: content,
                category: category,
                authorName: user.name ?? user.email.split('@').first,
              );

          if (mounted) {
            Navigator.pop(context);
            showAppNotification(context,
                message: 'Post shared with community!',
                type: NotificationType.success);
          }
        },
      ),
    );
  }

  Future<void> _handleLike(String postId) async {
    await ref.read(forumNotifierProvider.notifier).toggleLike(postId);
  }

  Future<void> _handleComment(String postId) async {
    if (_commentController.text.trim().isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await ref.read(forumNotifierProvider.notifier).addComment(
          postId: postId,
          content: _commentController.text.trim(),
          authorName: user.name ?? user.email.split('@').first,
        );

    _commentController.clear();
    // 刷新评论列表
    ref.invalidate(postCommentsProvider(postId));
    showAppNotification(context,
        message: 'Comment added', type: NotificationType.success);
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(forumPostsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostSheet,
        backgroundColor: AppColors.primary500,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCategoryFilter(),
            Expanded(
              child: postsAsync.when(
                loading: () => const Center(child: AppLoadingIndicator()),
                error: (e, _) => ErrorStateWidget(
                  message: 'Failed to load posts',
                  onRetry: () => ref.invalidate(forumPostsProvider),
                ),
                data: (posts) {
                  final filtered = _selectedCategory == 'All'
                      ? posts
                      : posts
                          .where((p) =>
                              p.category.displayName == _selectedCategory)
                          .toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(forumPostsProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _PostCard(
                        post: filtered[index],
                        isExpanded: _expandedPostId == filtered[index].id,
                        onToggleExpand: () {
                          setState(() {
                            _expandedPostId =
                                _expandedPostId == filtered[index].id
                                    ? null
                                    : filtered[index].id;
                          });
                        },
                        onLike: () => _handleLike(filtered[index].id),
                        commentController: _commentController,
                        onSubmitComment: () =>
                            _handleComment(filtered[index].id),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.forum, color: AppColors.primary500, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Community',
                    style: Theme.of(context).textTheme.headlineSmall),
                Text('Connect with pet parents',
                    style: TextStyle(color: AppColors.stone500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.stone800 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      isSelected ? null : Border.all(color: AppColors.stone200),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.stone600,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.stone300),
          const SizedBox(height: 16),
          Text('No posts yet',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.stone600)),
          const SizedBox(height: 8),
          Text('Be the first to share!',
              style: TextStyle(color: AppColors.stone400)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showCreatePostSheet,
            icon: const Icon(Icons.add),
            label: const Text('Create Post'),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final ForumPost post;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onLike;
  final TextEditingController commentController;
  final VoidCallback onSubmitComment;

  const _PostCard({
    required this.post,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onLike,
    required this.commentController,
    required this.onSubmitComment,
  });

  Color _getCategoryColor() {
    switch (post.category) {
      case ForumCategory.question:
        return Colors.orange;
      case ForumCategory.tip:
        return AppColors.mint500;
      case ForumCategory.story:
        return Colors.purple;
      case ForumCategory.emergency:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 展开时加载评论
    final commentsAsync = isExpanded
        ? ref.watch(postCommentsProvider(post.id))
        : const AsyncValue<List<ForumComment>>.data([]);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [AppColors.stone200, AppColors.stone300]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: post.authorAvatar != null
                            ? Text(post.authorAvatar!,
                                style: const TextStyle(fontSize: 20))
                            : Icon(Icons.person, color: AppColors.stone500),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.authorName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(_formatDate(post.createdAt),
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.stone400)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        post.category.displayName,
                        style: TextStyle(
                            color: _getCategoryColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Content
                Text(post.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(post.content,
                    style: TextStyle(color: AppColors.stone600, height: 1.4)),
                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.favorite_outline,
                      label: '${post.likesCount}',
                      color: post.likesCount > 5
                          ? AppColors.error
                          : AppColors.stone500,
                      onTap: onLike,
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: isExpanded
                          ? Icons.chat_bubble
                          : Icons.chat_bubble_outline,
                      label: '${post.commentsCount}',
                      color: isExpanded
                          ? AppColors.primary500
                          : AppColors.stone500,
                      onTap: onToggleExpand,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Comments Section
          if (isExpanded) ...[
            Divider(height: 1, color: AppColors.stone100),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Comment List - 使用 Provider 加载
                  commentsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                          child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Failed to load comments',
                          style: TextStyle(color: AppColors.error)),
                    ),
                    data: (comments) {
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text('No comments yet. Be the first!',
                              style: TextStyle(
                                  color: AppColors.stone400,
                                  fontStyle: FontStyle.italic)),
                        );
                      }
                      return Column(
                        children: [
                          ...comments.map((c) => _CommentItem(comment: c)),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),

                  // Comment Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            filled: true,
                            fillColor: AppColors.stone50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onSubmitComment,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary500,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.send,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final ForumComment comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.stone200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                comment.authorName.isNotEmpty
                    ? comment.authorName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.stone600,
                    fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.stone50,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(comment.authorName,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.stone700)),
                      Text(_formatDate(comment.createdAt),
                          style: TextStyle(
                              fontSize: 10, color: AppColors.stone400)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.content,
                      style:
                          TextStyle(fontSize: 13, color: AppColors.stone600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }
}

class _CreatePostSheet extends StatefulWidget {
  final Function(String title, String content, ForumCategory category) onPost;

  const _CreatePostSheet({required this.onPost});

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  ForumCategory _category = ForumCategory.question;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      showAppNotification(context,
          message: 'Please fill in all fields', type: NotificationType.error);
      return;
    }

    setState(() => _isLoading = true);
    await widget.onPost(_titleController.text.trim(),
        _contentController.text.trim(), _category);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.stone200,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary500),
                const SizedBox(width: 8),
                Text('New Post', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Give your post a title...',
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.stone400),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ForumCategory.values.map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  label: Text(cat.displayName),
                  selected: isSelected,
                  selectedColor: AppColors.primary100,
                  onSelected: (_) => setState(() => _category = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Post'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
