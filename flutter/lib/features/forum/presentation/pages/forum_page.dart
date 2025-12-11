import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ForumPage extends StatelessWidget {
  const ForumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.forum,
                      color: AppColors.primary500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Community',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Connect with other pet parents',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              const SizedBox(height: 24),
              
              // Filter tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(label: 'All', isSelected: true),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Question', isSelected: false),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Tip', isSelected: false),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Story', isSelected: false),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Create post button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.soft,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primary500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Share a tip or ask a question...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.stone400,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sample posts
              _PostCard(
                authorName: 'Sarah & Bella',
                authorAvatar: '🐕',
                title: 'Tips for thunderstorms?',
                content: 'My dog gets super anxious when it rains...',
                category: 'Question',
                likes: 12,
                comments: 3,
                timeAgo: '2h ago',
              ),
              
              const SizedBox(height: 12),
              
              _PostCard(
                authorName: 'Mike & Whiskers',
                authorAvatar: '🐈',
                title: 'Found a great new grain-free food!',
                content: 'Just wanted to share that "PurePaws" salmon recipe...',
                category: 'Tip',
                likes: 24,
                comments: 5,
                timeAgo: '5h ago',
              ),
              
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.stone800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.stone800 : AppColors.stone200,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.stone500,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String authorName;
  final String authorAvatar;
  final String title;
  final String content;
  final String category;
  final int likes;
  final int comments;
  final String timeAgo;

  const _PostCard({
    required this.authorName,
    required this.authorAvatar,
    required this.title,
    required this.content,
    required this.category,
    required this.likes,
    required this.comments,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.stone100,
                child: Text(authorAvatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      timeAgo,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: category == 'Question' 
                      ? AppColors.peach100 
                      : AppColors.mint100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: category == 'Question' 
                        ? AppColors.peach500 
                        : AppColors.mint500,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 18, color: AppColors.stone400),
              const SizedBox(width: 4),
              Text('$likes', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.stone400),
              const SizedBox(width: 4),
              Text('$comments', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}
