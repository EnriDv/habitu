import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/habit_catalog.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../habits/presentation/notifiers/habits_notifier.dart';
import '../notifiers/session_onboarding_notifier.dart';

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final PageController _pageController = PageController();
  final List<String> _selectedTemplateIndexes = [];
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishSetup(OnboardingNotifier onboarding) async {
    if (onboarding.user == null) return;

    await NotificationService().requestNotificationPermission(context);
    final habitsNotifier = context.read<HabitsNotifier>();

    for (final indexStr in _selectedTemplateIndexes) {
      final template = habitTemplateOptions[int.parse(indexStr)];
      await habitsNotifier.createHabit(
        habit: Habit(
          id: '',
          userId: onboarding.user!.id,
          title: template.title,
          description: template.description,
          frequencyType: 'daily',
          colorHex: template.colorHex,
          icon: template.emoji,
          isPublic: false,
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        token: 'offline_token',
      );
    }

    await onboarding.completeInitialSetup(
      focusAreas: onboarding.selectedFocusAreas,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<OnboardingNotifier>(
          builder: (context, onboarding, _) {
            return Stack(
              children: [
                Positioned(
                  top: -110,
                  right: -60,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withOpacity(0.07),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          if (_page > 0)
                            IconButton(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeInOut,
                                );
                              },
                              icon: const Icon(Icons.arrow_back_ios_new),
                            )
                          else
                            const SizedBox(width: 48),
                          Expanded(
                            child: Center(
                              child: Text(
                                _page == 0 ? 'Configura tu punto de partida' : 'Elige tus primeros habitos',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (page) {
                          setState(() {
                            _page = page;
                          });
                        },
                        children: [
                          _FocusAreasStep(
                            selectedAreas: onboarding.selectedFocusAreas,
                            onToggle: onboarding.toggleFocusArea,
                          ),
                          _TemplatesStep(
                            selectedTemplateIndexes: _selectedTemplateIndexes,
                            onToggle: (index) {
                              setState(() {
                                final key = index.toString();
                                if (_selectedTemplateIndexes.contains(key)) {
                                  _selectedTemplateIndexes.remove(key);
                                } else {
                                  _selectedTemplateIndexes.add(key);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: onboarding.isLoading
                          ? const CircularProgressIndicator(color: AppTheme.primaryColor)
                          : ElevatedButton(
                              onPressed: _page == 0
                                  ? (onboarding.selectedFocusAreas.isEmpty
                                      ? null
                                      : () {
                                          _pageController.nextPage(
                                            duration: const Duration(milliseconds: 240),
                                            curve: Curves.easeInOut,
                                          );
                                        })
                                  : () async {
                                      await _finishSetup(onboarding);
                                    },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                              ),
                              child: Text(
                                _page == 0
                                    ? 'Continuar'
                                    : _selectedTemplateIndexes.isEmpty
                                        ? 'Entrar sin templates'
                                        : 'Crear ${_selectedTemplateIndexes.length} habitos',
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FocusAreasStep extends StatelessWidget {
  final List<String> selectedAreas;
  final ValueChanged<String> onToggle;

  const _FocusAreasStep({
    required this.selectedAreas,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿En que quieres enfocarte primero?',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona una o varias areas para personalizar tus sugerencias iniciales.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: focusAreaOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final area = focusAreaOptions[index];
                final isSelected = selectedAreas.contains(area.id);
                return InkWell(
                  onTap: () => onToggle(area.id),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(area.emoji, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                area.title,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppTheme.primaryColor : AppTheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                area.description,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_off_outlined,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.outline,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplatesStep extends StatelessWidget {
  final List<String> selectedTemplateIndexes;
  final ValueChanged<int> onToggle;

  const _TemplatesStep({
    required this.selectedTemplateIndexes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tus primeros templates',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Puedes empezar con algunas bases y luego ajustar todo desde la app.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: habitTemplateOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final template = habitTemplateOptions[index];
                final isSelected = selectedTemplateIndexes.contains(index.toString());
                return InkWell(
                  onTap: () => onToggle(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.tertiaryColor.withOpacity(0.08)
                          : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.tertiaryColor
                            : Colors.white.withOpacity(0.05),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(
                            int.parse(template.colorHex.replaceAll('#', '0xFF')),
                          ).withOpacity(0.2),
                          child: Text(template.emoji, style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.title,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                template.description,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_off_outlined,
                          color: isSelected ? AppTheme.tertiaryColor : AppTheme.outline,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
