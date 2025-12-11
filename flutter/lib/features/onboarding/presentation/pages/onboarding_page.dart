import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/models/models.dart';
import '../../../../core/providers/providers.dart';
import '../../../../shared/widgets/widgets.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form data
  String _name = '';
  PetSpecies _species = PetSpecies.dog;
  String _breed = '';
  int _ageMonths = 0;
  PetGender _gender = PetGender.male;
  double _weightKg = 0;
  bool _isNeutered = false;
  String _allergies = '';
  Uint8List? _avatarBytes;
  final Map<BodyPart, Uint8List> _bodyPartImages = {};

  void _nextStep() {
    if (_currentStep == 0) {
      if (_name.isEmpty) {
        showAppNotification(context, message: "Please enter your pet's name", type: NotificationType.error);
        return;
      }
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleComplete() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(petNotifierProvider.notifier).createPet(
        name: _name,
        species: _species,
        breed: _breed.isEmpty ? 'Unknown' : _breed,
        ageMonths: _ageMonths,
        gender: _gender,
        weightKg: _weightKg,
        isNeutered: _isNeutered,
        allergies: _allergies.isEmpty ? null : _allergies,
        avatarBytes: _avatarBytes,
        bodyPartImages: _bodyPartImages.isEmpty ? null : _bodyPartImages,
      );

      if (mounted) {
        showAppNotification(context, message: 'Welcome to PawPrint, $_name!', type: NotificationType.success);
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        showAppNotification(context, message: 'Failed to create profile: $e', type: NotificationType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAvatar() async {
    final result = await ImagePickerHelper.showPicker(context);
    if (result != null) {
      setState(() => _avatarBytes = result.bytes);
    }
  }

  Future<void> _pickBodyPartImage(BodyPart part) async {
    final result = await ImagePickerHelper.showPicker(context);
    if (result != null) {
      setState(() => _bodyPartImages[part] = result.bytes);
      showAppNotification(context, message: 'Uploaded photo for ${part.displayName}', type: NotificationType.success);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: _isLoading,
          message: 'Creating profile...',
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.mint100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.pets, size: 32, color: AppColors.primary600),
                    ),
                    const SizedBox(height: 16),
                    Text('Welcome Friend', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text("Let's get to know your companion", style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _currentStep ? 32 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: index <= _currentStep ? AppColors.primary500 : AppColors.primary200,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: AppShadows.card,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) => setState(() => _currentStep = index),
                      children: [
                        _BasicInfoStep(
                          name: _name, species: _species, breed: _breed,
                          ageMonths: _ageMonths, gender: _gender, avatarBytes: _avatarBytes,
                          onNameChanged: (v) => setState(() => _name = v),
                          onSpeciesChanged: (v) => setState(() => _species = v),
                          onBreedChanged: (v) => setState(() => _breed = v),
                          onAgeChanged: (v) => setState(() => _ageMonths = v),
                          onGenderChanged: (v) => setState(() => _gender = v),
                          onPickAvatar: _pickAvatar,
                        ),
                        _MedicalInfoStep(
                          weightKg: _weightKg, isNeutered: _isNeutered, allergies: _allergies,
                          onWeightChanged: (v) => setState(() => _weightKg = v),
                          onNeuteredChanged: (v) => setState(() => _isNeutered = v),
                          onAllergiesChanged: (v) => setState(() => _allergies = v),
                        ),
                        _BodyScanStep(
                          bodyPartImages: _bodyPartImages,
                          onPickImage: _pickBodyPartImage,
                          onRemoveImage: (part) => setState(() => _bodyPartImages.remove(part)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      SizedBox(
                        width: 56, height: 56,
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: const Icon(Icons.arrow_back),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _nextStep,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_currentStep == 2 ? 'Finish Profile' : 'Next Step'),
                              const SizedBox(width: 8),
                              Icon(_currentStep == 2 ? Icons.check : Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BasicInfoStep extends StatelessWidget {
  final String name;
  final PetSpecies species;
  final String breed;
  final int ageMonths;
  final PetGender gender;
  final Uint8List? avatarBytes;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<PetSpecies> onSpeciesChanged;
  final ValueChanged<String> onBreedChanged;
  final ValueChanged<int> onAgeChanged;
  final ValueChanged<PetGender> onGenderChanged;
  final VoidCallback onPickAvatar;

  const _BasicInfoStep({required this.name, required this.species, required this.breed, required this.ageMonths, required this.gender, required this.avatarBytes, required this.onNameChanged, required this.onSpeciesChanged, required this.onBreedChanged, required this.onAgeChanged, required this.onGenderChanged, required this.onPickAvatar});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text('Basic Info', style: Theme.of(context).textTheme.titleLarge)),
          Center(child: Text('The essentials', style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: onPickAvatar,
              child: Stack(
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary100, borderRadius: BorderRadius.circular(28),
                      image: avatarBytes != null ? DecorationImage(image: MemoryImage(avatarBytes!), fit: BoxFit.cover) : null,
                    ),
                    child: avatarBytes == null ? const Icon(Icons.pets, size: 40, color: AppColors.primary400) : null,
                  ),
                  Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary500, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.camera_alt, size: 16, color: Colors.white))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Pet\'s Name', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          TextFormField(initialValue: name, onChanged: onNameChanged, decoration: const InputDecoration(hintText: 'e.g. Luna')),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Species', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<PetSpecies>(value: species, onChanged: (v) => onSpeciesChanged(v!), items: PetSpecies.values.map((s) => DropdownMenuItem(value: s, child: Text(s.displayName))).toList()),
            ])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Breed', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              TextFormField(initialValue: breed, onChanged: onBreedChanged, decoration: const InputDecoration(hintText: 'Type...')),
            ])),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Age (Months)', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              TextFormField(initialValue: ageMonths > 0 ? ageMonths.toString() : '', keyboardType: TextInputType.number, onChanged: (v) => onAgeChanged(int.tryParse(v) ?? 0), decoration: const InputDecoration(hintText: '0')),
            ])),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Gender', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              GenderToggle(selected: gender.displayName, onChanged: (v) => onGenderChanged(PetGender.fromString(v))),
            ])),
          ]),
        ],
      ),
    );
  }
}

class _MedicalInfoStep extends StatelessWidget {
  final double weightKg;
  final bool isNeutered;
  final String allergies;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<bool> onNeuteredChanged;
  final ValueChanged<String> onAllergiesChanged;

  const _MedicalInfoStep({required this.weightKg, required this.isNeutered, required this.allergies, required this.onWeightChanged, required this.onNeuteredChanged, required this.onAllergiesChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.peach100, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.medical_services, size: 32, color: AppColors.peach500))),
          const SizedBox(height: 16),
          Center(child: Text('Medical History', style: Theme.of(context).textTheme.titleLarge)),
          Center(child: Text('Help us track their health', style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(height: 24),
          Text('Current Weight (kg)', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          TextFormField(initialValue: weightKg > 0 ? weightKg.toString() : '', keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) => onWeightChanged(double.tryParse(v) ?? 0), decoration: const InputDecoration(hintText: '0.0'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          AppSwitch(value: isNeutered, onChanged: onNeuteredChanged, title: 'Neutered / Spayed?', subtitle: 'Has your pet had this procedure?'),
          const SizedBox(height: 24),
          Text('Allergies', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          TextFormField(initialValue: allergies, onChanged: onAllergiesChanged, maxLines: 3, decoration: const InputDecoration(hintText: 'e.g. Chicken, Pollen (Optional)')),
        ],
      ),
    );
  }
}

class _BodyScanStep extends StatelessWidget {
  final Map<BodyPart, Uint8List> bodyPartImages;
  final Function(BodyPart) onPickImage;
  final Function(BodyPart) onRemoveImage;

  const _BodyScanStep({required this.bodyPartImages, required this.onPickImage, required this.onRemoveImage});

  @override
  Widget build(BuildContext context) {
    final parts = [BodyPart.eyes, BodyPart.ears, BodyPart.mouthTeeth, BodyPart.paws, BodyPart.skinFur];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.sky100, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.camera_alt, size: 32, color: AppColors.sky500)),
          const SizedBox(height: 16),
          Text('Body Scan', style: Theme.of(context).textTheme.titleLarge),
          Text('Baseline photos for AI comparison', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          InfoCard(icon: Icons.favorite, iconColor: AppColors.peach500, backgroundColor: AppColors.peach100, message: 'Pro Tip: These photos help our AI spot changes later. Try to get clear shots in good lighting!'),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12,
            children: parts.map((part) {
              final hasImage = bodyPartImages.containsKey(part);
              return ImageUploadPlaceholder(imageBytes: bodyPartImages[part], label: part.displayName, onTap: () => onPickImage(part), onRemove: hasImage ? () => onRemoveImage(part) : null);
            }).toList(),
          ),
        ],
      ),
    );
  }
}
