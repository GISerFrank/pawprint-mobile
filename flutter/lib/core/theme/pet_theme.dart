import 'package:flutter/material.dart';
import '../models/models.dart';

/// 宠物主题配色方案
class PetTheme {
  final String name;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;
  final Color accentLight;
  final Color background;
  final Color cardBackground;
  final Gradient gradient;
  final Gradient headerGradient;
  final String emoji;
  final IconData icon;

  const PetTheme({
    required this.name,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.accentLight,
    required this.background,
    required this.cardBackground,
    required this.gradient,
    required this.headerGradient,
    required this.emoji,
    required this.icon,
  });

  /// 根据宠物种类获取主题
  factory PetTheme.fromSpecies(PetSpecies species) {
    switch (species) {
      case PetSpecies.dog:
        return PetTheme.dog;
      case PetSpecies.cat:
        return PetTheme.cat;
      case PetSpecies.bird:
        return PetTheme.bird;
      case PetSpecies.rabbit:
        return PetTheme.rabbit;
      case PetSpecies.fish:
        return PetTheme.fish;
      case PetSpecies.other:
        return PetTheme.defaultTheme;
    }
  }

  /// 🐕 狗狗主题 - 温暖的橙棕色系
  static const PetTheme dog = PetTheme(
    name: 'Dog',
    primary: Color(0xFFE67E22),      // 暖橙色
    primaryLight: Color(0xFFFDF2E9),
    primaryDark: Color(0xFFD35400),
    accent: Color(0xFF8B4513),        // 棕色
    accentLight: Color(0xFFFAE5D3),
    background: Color(0xFFFDF8F3),    // 温暖奶油色
    cardBackground: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFFE67E22), Color(0xFFF39C12)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFFE67E22), Color(0xFFD35400)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    emoji: '🐕',
    icon: Icons.pets,
  );

  /// 🐱 猫咪主题 - 优雅的紫粉色系
  static const PetTheme cat = PetTheme(
    name: 'Cat',
    primary: Color(0xFF9B59B6),      // 紫色
    primaryLight: Color(0xFFF5EEF8),
    primaryDark: Color(0xFF8E44AD),
    accent: Color(0xFFE91E63),        // 粉色
    accentLight: Color(0xFFFCE4EC),
    background: Color(0xFFFAF5FC),    // 淡紫奶油色
    cardBackground: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFF9B59B6), Color(0xFFE91E63)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    emoji: '🐱',
    icon: Icons.catching_pokemon,
  );

  /// 🐦 鸟类主题 - 清新的蓝绿色系
  static const PetTheme bird = PetTheme(
    name: 'Bird',
    primary: Color(0xFF1ABC9C),      // 青绿色
    primaryLight: Color(0xFFE8F8F5),
    primaryDark: Color(0xFF16A085),
    accent: Color(0xFF3498DB),        // 天蓝色
    accentLight: Color(0xFFEBF5FB),
    background: Color(0xFFF0FFFC),    // 清新薄荷色
    cardBackground: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFF1ABC9C), Color(0xFF3498DB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF1ABC9C), Color(0xFF16A085)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    emoji: '🐦',
    icon: Icons.flutter_dash,
  );

  /// 🐰 兔子主题 - 可爱的粉白色系
  static const PetTheme rabbit = PetTheme(
    name: 'Rabbit',
    primary: Color(0xFFFF6B9D),      // 粉红色
    primaryLight: Color(0xFFFFF0F5),
    primaryDark: Color(0xFFE91E63),
    accent: Color(0xFFFFB6C1),        // 浅粉色
    accentLight: Color(0xFFFFF5F7),
    background: Color(0xFFFFF9FB),    // 柔和粉色
    cardBackground: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFFFF6B9D), Color(0xFFFFB6C1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFFFF6B9D), Color(0xFFE91E63)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    emoji: '🐰',
    icon: Icons.cruelty_free,
  );

  /// 🐟 鱼类主题 - 深邃的蓝色系
  static const PetTheme fish = PetTheme(
    name: 'Fish',
    primary: Color(0xFF2980B9),      // 海蓝色
    primaryLight: Color(0xFFEBF5FB),
    primaryDark: Color(0xFF1A5276),
    accent: Color(0xFF00BCD4),        // 青色
    accentLight: Color(0xFFE0F7FA),
    background: Color(0xFFF0F8FF),    // 浅蓝色
    cardBackground: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFF2980B9), Color(0xFF00BCD4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF2980B9), Color(0xFF1A5276)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    emoji: '🐟',
    icon: Icons.water,
  );

  /// 默认主题 - 经典绿色系 (与原主题一致)
  static const PetTheme defaultTheme = PetTheme(
    name: 'Default',
    primary: Color(0xFF14B8A6),      // Teal
    primaryLight: Color(0xFFF0FDFA),
    primaryDark: Color(0xFF0D9488),
    accent: Color(0xFF10B981),        // Mint
    accentLight: Color(0xFFD1FAE5),
    background: Color(0xFFFDFBF7),    // Cream
    cardBackground: Colors.white,
    gradient: LinearGradient(
      colors: [Color(0xFF14B8A6), Color(0xFF10B981)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    headerGradient: LinearGradient(
      colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    emoji: '🐾',
    icon: Icons.pets,
  );

  /// 获取带透明度的主色
  Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  
  /// 获取带透明度的强调色
  Color accentWithOpacity(double opacity) => accent.withOpacity(opacity);
}

/// 所有可用主题列表
class PetThemes {
  static const List<PetTheme> all = [
    PetTheme.dog,
    PetTheme.cat,
    PetTheme.bird,
    PetTheme.rabbit,
    PetTheme.fish,
    PetTheme.defaultTheme,
  ];

  static PetTheme getBySpecies(PetSpecies species) => PetTheme.fromSpecies(species);
}
