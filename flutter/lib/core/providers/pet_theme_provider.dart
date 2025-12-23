import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/pet_theme.dart';
import '../models/models.dart';
import 'pet_provider.dart';

/// 当前宠物的主题
final currentPetThemeProvider = Provider<PetTheme>((ref) {
  final petAsync = ref.watch(currentPetProvider);
  
  return petAsync.when(
    loading: () => PetTheme.defaultTheme,
    error: (_, __) => PetTheme.defaultTheme,
    data: (pet) {
      if (pet == null) return PetTheme.defaultTheme;
      return PetTheme.fromSpecies(pet.species);
    },
  );
});

/// 宠物主题扩展 - 用于快速访问主题属性
extension PetThemeX on WidgetRef {
  PetTheme get petTheme => watch(currentPetThemeProvider);
}
