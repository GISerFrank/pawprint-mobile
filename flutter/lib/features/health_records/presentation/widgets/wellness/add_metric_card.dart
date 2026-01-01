import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/pet_theme.dart';
import '../../../../../core/models/models.dart';
import '../../../../../core/providers/wellness_provider.dart';

/// 数据记录形式定义
class DataRecordType {
  final String id;
  final String name;
  final String nameZh;
  final String icon;
  final MetricValueType valueType;
  final String description;

  const DataRecordType({
    required this.id,
    required this.name,
    required this.nameZh,
    required this.icon,
    required this.valueType,
    required this.description,
  });
}

/// 可选的数据记录形式
class DataRecordTypes {
  static const List<DataRecordType> all = [
    DataRecordType(
      id: 'rating',
      name: 'Rating',
      nameZh: '评分',
      icon: '⭐',
      valueType: MetricValueType.range,
      description: '1-5 scale assessment',
    ),
    DataRecordType(
      id: 'value',
      name: 'Value',
      nameZh: '数值',
      icon: '🔢',
      valueType: MetricValueType.number,
      description: 'Numeric measurement',
    ),
    DataRecordType(
      id: 'description',
      name: 'Description',
      nameZh: '描述',
      icon: '📝',
      valueType: MetricValueType.text,
      description: 'Text notes',
    ),
    DataRecordType(
      id: 'image',
      name: 'Image',
      nameZh: '图片',
      icon: '📷',
      valueType: MetricValueType.image,
      description: 'Photo record',
    ),
    DataRecordType(
      id: 'video',
      name: 'Video',
      nameZh: '视频',
      icon: '🎬',
      valueType: MetricValueType.video,
      description: 'Video record',
    ),
  ];
}

/// 添加自定义指标卡片
class AddMetricCard extends StatelessWidget {
  final PetTheme theme;
  final String petId;

  const AddMetricCard({
    super.key,
    required this.theme,
    required this.petId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.stone200,
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showAddMetricSheet(context),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.stone100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: AppColors.stone500,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add Metric',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.stone500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddMetricSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMetricSheet(
        petId: petId,
        theme: theme,
      ),
    );
  }
}

/// 添加指标的底部弹窗 - Step 1: 选择类别
class AddMetricSheet extends ConsumerStatefulWidget {
  final String petId;
  final PetTheme theme;

  const AddMetricSheet({
    super.key,
    required this.petId,
    required this.theme,
  });

  @override
  ConsumerState<AddMetricSheet> createState() => _AddMetricSheetState();
}

class _AddMetricSheetState extends ConsumerState<AddMetricSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 拖动指示器和标题
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.stone300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add Custom Metric',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select a category to get started',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.stone500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 9个类别网格
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: MetricCategory.values.length,
              itemBuilder: (context, index) {
                final category = MetricCategory.values[index];
                return _CategoryCard(
                  category: category,
                  theme: widget.theme,
                  onTap: () => _onCategorySelected(category),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _onCategorySelected(MetricCategory category) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateMetricSheet(
        petId: widget.petId,
        theme: widget.theme,
        category: category,
      ),
    );
  }
}

/// 类别卡片
class _CategoryCard extends StatelessWidget {
  final MetricCategory category;
  final PetTheme theme;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.stone700,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                category.nameZh,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.stone500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 2: 填写指标详情
class CreateMetricSheet extends ConsumerStatefulWidget {
  final String petId;
  final PetTheme theme;
  final MetricCategory category;

  const CreateMetricSheet({
    super.key,
    required this.petId,
    required this.theme,
    required this.category,
  });

  @override
  ConsumerState<CreateMetricSheet> createState() => _CreateMetricSheetState();
}

class _CreateMetricSheetState extends ConsumerState<CreateMetricSheet> {
  final _nameController = TextEditingController();
  DataRecordType _selectedType = DataRecordTypes.all[0]; // 默认 rating
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖动指示器
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.stone300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 返回按钮和标题
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => AddMetricSheet(
                          petId: widget.petId,
                          theme: widget.theme,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.stone100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: AppColors.stone600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Metric',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              widget.category.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.category.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: widget.theme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 子项检查提示
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.theme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.theme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: widget.theme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Inspection hints',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.theme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.category.hints.map((hint) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            hint,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.stone600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 名称输入
              Text(
                'Metric Name',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., ${widget.category.hints.first}',
                  hintStyle: TextStyle(color: AppColors.stone400),
                  filled: true,
                  fillColor: AppColors.stone50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.theme.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 数据记录形式选择
              Text(
                'Record Type',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DataRecordTypes.all.map((type) {
                  final isSelected = type.id == _selectedType.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.theme.primary
                            : AppColors.stone100,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: AppColors.stone200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            type.icon,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            type.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.stone600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              // 选中类型的描述
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _selectedType.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.stone500,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveMetric,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.theme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Metric',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveMetric() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a metric name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success = await ref
          .read(wellnessScoreNotifierProvider.notifier)
          .createCustomMetric(
            petId: widget.petId,
            name: name,
            description: '',
            emoji: widget.category.emoji,
            valueType: _selectedType.valueType,
            metricCategory: widget.category,
          );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.category.emoji} $name created!'),
            backgroundColor: AppColors.green500,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
