import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:habitu_ui/habitu_ui.dart';
import '../../../../core/di/injection_container.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../habits/presentation/notifiers/habits_notifier.dart';
import '../notifiers/onboarding_notifier.dart';
import '../../../../core/services/notification_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  
  // Suggested habits list
  final List<Map<String, String>> _suggestedHabits = [
    {
      'title': 'Estudiar sin celular 30 min',
      'emoji': '📚',
      'category': 'Estudio',
      'color': '#A7C8FF',
      'description': 'Mantén tu enfoque total alejado de las redes.'
    },
    {
      'title': 'Dormir 7 horas',
      'emoji': '🛌',
      'category': 'Bienestar',
      'color': '#E2D6B2',
      'description': 'El descanso óptimo para el cerebro.'
    },
    {
      'title': 'Tomar 2L de agua',
      'emoji': '💧',
      'category': 'Salud',
      'color': '#96D3BD',
      'description': 'Mantente hidratado durante tus clases.'
    },
    {
      'title': 'Avanzar Proyecto de Grado',
      'emoji': '🎓',
      'category': 'Estudio',
      'color': '#D0B2E2',
      'description': 'Escribe al menos una página o haz investigación.'
    },
    {
      'title': 'Calistenia en el campus',
      'emoji': '🏃',
      'category': 'Deporte',
      'color': '#E2B2B2',
      'description': 'Mueve tu cuerpo 20 min al terminar clases.'
    }
  ];

  final List<String> _selectedHabitIndexes = [];

  final List<Map<String, String>> _personas = [
    {
      'name': 'Pensador Profundo (Deep Thinker)',
      'description': 'Buscas la excelencia académica y la autorreflexión constante.',
      'icon': '🧠'
    },
    {
      'name': 'Investigador Riguroso (Rigorous Researcher)',
      'description': 'Enfoque en datos, lecturas académicas amplias y metodología.',
      'icon': '🔬'
    },
    {
      'name': 'Creador Creativo (Creative Mind)',
      'description': 'Diseño, innovación y resolución alternativa de problemas.',
      'icon': '🎨'
    }
  ];

  final List<String> _academicPrograms = [
    'Ingeniería de Sistemas',
    'Administración de Empresas',
    'Ingeniería Civil',
    'Derecho',
    'Psicología',
    'Comunicación Social'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<OnboardingNotifier>(
        builder: (context, notifier, _) {
          return Stack(
            children: [
              // Ambient backgrounds
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.tertiaryColor.withOpacity(0.04),
                  ),
                ),
              ),
              
              SafeArea(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    notifier.setPage(page);
                  },
                  children: [
                    _buildStepWelcome(notifier),
                    _buildStepIdentity(notifier),
                    _buildStepHabits(notifier),
                    _buildStepAuth(notifier),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- STEP 1: WELCOME & SLOGAN ---
  Widget _buildStepWelcome(OnboardingNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          // App Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceContainer,
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 40,
                  spreadRadius: 5,
                )
              ],
            ),
            child: const Icon(
              Icons.eco,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Habitü',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'La disciplina no es castigo, es libertad. Construye tu rutina.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          // Buttons
          HabituButton(
            label: 'Comenzar Mi Viaje',
            onPressed: _nextPage,
            fullWidth: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Diseñado para estudiantes y mentes rigurosas.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: PERSONA & CAREER ---
  Widget _buildStepIdentity(OnboardingNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: _prevPage,
            icon: const Icon(Icons.arrow_back_ios, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            'Define Tu Identidad',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '¿Qué tipo de estudiante aspiras a ser hoy en la universidad?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Careers Dropdown
          DropdownButtonFormField<String>(
            value: notifier.academicProgram,
            decoration: const InputDecoration(
              labelText: 'Tu Carrera',
              hintText: 'Selecciona tu carrera',
            ),
            dropdownColor: AppTheme.surfaceContainerHigh,
            items: _academicPrograms.map((career) {
              return DropdownMenuItem(
                value: career,
                child: Text(career, style: const TextStyle(fontFamily: 'Inter')),
              );
            }).toList(),
            onChanged: (val) {
              notifier.selectAcademicProgram(val);
            },
          ),
          
          const SizedBox(height: 24),
          Text(
            'Selecciona tu Arquetipo:',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Personas List
          Expanded(
            child: ListView.separated(
              itemCount: _personas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final item = _personas[idx];
                final isSelected = notifier.persona == item['name'];
                return InkWell(
                  onTap: () {
                    notifier.selectPersona(item['name']);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(item['icon']!, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name']!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppTheme.primaryColor : AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['description']!,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          HabituButton(
            label: 'Continuar',
            onPressed: (notifier.persona != null && notifier.academicProgram != null) ? _nextPage : null,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  // --- STEP 3: INITIAL HABITS ---
  Widget _buildStepHabits(OnboardingNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: _prevPage,
            icon: const Icon(Icons.arrow_back_ios, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            'Tus Primeros Hábitos',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Elige uno o más hábitos recomendados para comenzar tu racha académica. Los guardaremos localmente.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Habits list
          Expanded(
            child: ListView.separated(
              itemCount: _suggestedHabits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final habit = _suggestedHabits[idx];
                final isSelected = _selectedHabitIndexes.contains(idx.toString());
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedHabitIndexes.remove(idx.toString());
                      } else {
                        _selectedHabitIndexes.add(idx.toString());
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.tertiaryColor.withOpacity(0.08) : AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.tertiaryColor : Colors.white.withOpacity(0.05),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(int.parse(habit['color']!.replaceAll('#', '0xFF'))).withOpacity(0.2),
                          child: Text(habit['emoji']!, style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit['title']!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                habit['description']!,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_off_outlined,
                          color: isSelected ? AppTheme.tertiaryColor : AppTheme.outline,
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          HabituButton(
            label: _selectedHabitIndexes.isEmpty
                ? 'Saltar y continuar'
                : 'Crear ${_selectedHabitIndexes.length} hábitos',
            onPressed: _nextPage,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  // --- STEP 4: AUTH & REGISTRATION ---
  Widget _buildStepAuth(OnboardingNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: _prevPage,
                icon: const Icon(Icons.arrow_back_ios, size: 20),
              ),
              const SizedBox(height: 16),
              Text(
                'Último Paso: Tu Cuenta',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa tu correo electrónico para resguardar tu progreso, o inicia sesión de forma anónima.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              
              // Full name input
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  hintText: 'Ej. Enrique Vargas',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                style: const TextStyle(fontFamily: 'Inter'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  return null;
                },
                onChanged: (val) {
                  notifier.setFullName(val);
                },
              ),
              const SizedBox(height: 20),
              
              // Email input
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  hintText: 'ejemplo@correo.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                style: const TextStyle(fontFamily: 'Inter'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Por favor ingresa tu correo electrónico';
                  }
                  if (!val.trim().contains('@') || !val.trim().contains('.')) {
                    return 'Ingresa un correo electrónico válido';
                  }
                  return null;
                },
                onChanged: (val) {
                  notifier.setEmail(val);
                },
              ),
              
              if (notifier.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  notifier.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontFamily: 'Inter'),
                ),
              ],
              
              const SizedBox(height: 40),
              
              // Primary button: Register
              notifier.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: CircularProgressIndicator(color: AppTheme.primaryColor),
                      ),
                    )
                  : HabituButton(
                      label: 'Registrar e Iniciar',
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await notifier.completeOnboarding(anonymous: false);
                          if (success) {
                            await NotificationService().requestNotificationPermission(context);
                            await _saveInitialHabits(notifier.user!.id);
                          }
                        }
                      },
                      fullWidth: true,
                    ),
              
              const SizedBox(height: 12),
              
              // Secondary button: Anonymous
              Center(
                child: notifier.isLoading
                    ? const SizedBox.shrink()
                    : HabituButton.outlined(
                        label: 'Empezar sin registrarme',
                        onPressed: () async {
                          final success = await notifier.completeOnboarding(anonymous: true);
                          if (success) {
                            await NotificationService().requestNotificationPermission(context);
                            await _saveInitialHabits(notifier.user!.id);
                          }
                        },
                        fullWidth: true,
                      ),
              ),
              
              if (notifier.localUsers.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    '¿Ya estuviste aquí?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Continúa con una cuenta anterior en este dispositivo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notifier.localUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final prevUser = notifier.localUsers[idx];
                    final isAnon = prevUser.email.startsWith('anonimo_') && prevUser.email.endsWith('@habitu.app');
                    final displayEmail = isAnon ? 'Sesión Temporal' : prevUser.email;
                    
                    return HabituCard(
                      color: AppTheme.surfaceContainerLow,
                      borderRadius: 16.0,
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.05),
                      ),
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            isAnon ? Icons.person_outline : Icons.email_outlined,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(
                          prevUser.fullName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          displayEmail,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant.withOpacity(0.8),
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: notifier.isLoading ? null : () async {
                          final success = await notifier.loginWithExistingUser(prevUser.id);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Bienvenido de nuevo, ' + prevUser.fullName + '!'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper to save chosen suggested habits to Drift
  Future<void> _saveInitialHabits(String userId) async {
    final habitsNotifier = context.read<HabitsNotifier>();
    for (final indexStr in _selectedHabitIndexes) {
      final index = int.parse(indexStr);
      final suggested = _suggestedHabits[index];
      
      final habit = Habit(
        id: '', // Will be generated in repository
        userId: userId,
        title: suggested['title']!,
        description: suggested['description']!,
        frequencyType: 'daily',
        colorHex: suggested['color']!,
        icon: suggested['emoji']!,
        isPublic: false,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await habitsNotifier.createHabit(
        habit: habit,
        token: 'offline_token',
      );
    }
  }
}
