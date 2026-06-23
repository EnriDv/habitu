class HabitCategoryOption {
  final String name;
  final String emoji;

  const HabitCategoryOption({
    required this.name,
    required this.emoji,
  });
}

class FocusAreaOption {
  final String id;
  final String title;
  final String description;
  final String emoji;

  const FocusAreaOption({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
  });
}

class HabitTemplateOption {
  final String title;
  final String description;
  final String category;
  final String colorHex;
  final String emoji;

  const HabitTemplateOption({
    required this.title,
    required this.description,
    required this.category,
    required this.colorHex,
    required this.emoji,
  });
}

const habitCategoryOptions = <HabitCategoryOption>[
  HabitCategoryOption(name: 'Salud', emoji: '💧'),
  HabitCategoryOption(name: 'Productividad', emoji: '⚡'),
  HabitCategoryOption(name: 'Bienestar', emoji: '🧘'),
  HabitCategoryOption(name: 'Relaciones', emoji: '💬'),
  HabitCategoryOption(name: 'Aprendizaje', emoji: '📚'),
  HabitCategoryOption(name: 'Hogar', emoji: '🏡'),
  HabitCategoryOption(name: 'Finanzas', emoji: '💸'),
];

const focusAreaOptions = <FocusAreaOption>[
  FocusAreaOption(
    id: 'health',
    title: 'Salud',
    description: 'Sueño, hidratación, movimiento y energía diaria.',
    emoji: '💪',
  ),
  FocusAreaOption(
    id: 'productivity',
    title: 'Productividad',
    description: 'Menos fricción, más enfoque y mejor ejecución.',
    emoji: '⚡',
  ),
  FocusAreaOption(
    id: 'wellbeing',
    title: 'Bienestar',
    description: 'Calma mental, pausas y equilibrio personal.',
    emoji: '🧘',
  ),
  FocusAreaOption(
    id: 'relationships',
    title: 'Relaciones',
    description: 'Tiempo de calidad y vínculos que quieres cuidar.',
    emoji: '💬',
  ),
  FocusAreaOption(
    id: 'learning',
    title: 'Aprendizaje',
    description: 'Leer, estudiar, practicar o desarrollar una habilidad.',
    emoji: '📚',
  ),
  FocusAreaOption(
    id: 'home',
    title: 'Hogar',
    description: 'Orden, limpieza y pequeñas tareas que sostienen tu rutina.',
    emoji: '🏡',
  ),
  FocusAreaOption(
    id: 'finance',
    title: 'Finanzas',
    description: 'Ahorro, registro de gastos y decisiones más conscientes.',
    emoji: '💸',
  ),
];

const habitTemplateOptions = <HabitTemplateOption>[
  HabitTemplateOption(
    title: 'Beber 2L de agua',
    emoji: '💧',
    category: 'Salud',
    colorHex: '#96D3BD',
    description: 'Mantén una hidratación consistente durante el día.',
  ),
  HabitTemplateOption(
    title: 'Caminar 20 minutos',
    emoji: '🚶',
    category: 'Salud',
    colorHex: '#E2B2B2',
    description: 'Activa el cuerpo con un bloque corto de movimiento.',
  ),
  HabitTemplateOption(
    title: 'Dormir antes de las 23:00',
    emoji: '🌙',
    category: 'Salud',
    colorHex: '#8FA8FF',
    description: 'Protege tu energía con una hora de descanso más estable.',
  ),
  HabitTemplateOption(
    title: 'Preparar comida casera',
    emoji: '🥗',
    category: 'Salud',
    colorHex: '#FFB36B',
    description: 'Reduce fricción alimentaria dejando una comida lista con anticipación.',
  ),
  HabitTemplateOption(
    title: 'Planificar el día',
    emoji: '🗓️',
    category: 'Productividad',
    colorHex: '#A7C8FF',
    description: 'Define tus prioridades antes de entrar en ejecución.',
  ),
  HabitTemplateOption(
    title: 'Bloque de enfoque de 25 min',
    emoji: '⏱️',
    category: 'Productividad',
    colorHex: '#7FB3FF',
    description: 'Reserva un sprint breve sin interrupciones para avanzar en lo importante.',
  ),
  HabitTemplateOption(
    title: 'Vaciar bandeja de entrada',
    emoji: '📥',
    category: 'Productividad',
    colorHex: '#B5C9FF',
    description: 'Procesa mensajes y pendientes para empezar con claridad.',
  ),
  HabitTemplateOption(
    title: 'Leer 10 páginas',
    emoji: '📚',
    category: 'Aprendizaje',
    colorHex: '#D0B2E2',
    description: 'Haz progreso sostenido en libros, cursos o estudio.',
  ),
  HabitTemplateOption(
    title: '10 minutos de lectura',
    emoji: '📘',
    category: 'Aprendizaje',
    colorHex: '#C8B6FF',
    description: 'Avanza en un libro o curso aunque sea en bloques cortos.',
  ),
  HabitTemplateOption(
    title: 'Repasar apuntes o ideas',
    emoji: '🧠',
    category: 'Aprendizaje',
    colorHex: '#D9C4FF',
    description: 'Consolida lo aprendido con una revisión breve al final del día.',
  ),
  HabitTemplateOption(
    title: 'Meditar 5 minutos',
    emoji: '🧘',
    category: 'Bienestar',
    colorHex: '#E2D6B2',
    description: 'Baja el ruido mental con una pausa breve y consciente.',
  ),
  HabitTemplateOption(
    title: 'Escribir 3 líneas de diario',
    emoji: '✍️',
    category: 'Bienestar',
    colorHex: '#F7D6A0',
    description: 'Baja la carga mental escribiendo lo más importante del día.',
  ),
  HabitTemplateOption(
    title: 'Pausa de respiración',
    emoji: '🌿',
    category: 'Bienestar',
    colorHex: '#E6D58A',
    description: 'Toma dos minutos para bajar revoluciones y volver con calma.',
  ),
  HabitTemplateOption(
    title: 'Ordenar 10 minutos',
    emoji: '🏡',
    category: 'Hogar',
    colorHex: '#B8D4E3',
    description: 'Mantén tu espacio funcional con una acción pequeña diaria.',
  ),
  HabitTemplateOption(
    title: 'Tender la cama',
    emoji: '🛏️',
    category: 'Hogar',
    colorHex: '#9BC7D9',
    description: 'Empieza el día con una acción simple que ordena el espacio.',
  ),
  HabitTemplateOption(
    title: 'Cerrar la cocina limpia',
    emoji: '🧽',
    category: 'Hogar',
    colorHex: '#89B8CC',
    description: 'Deja lista la cocina para que el siguiente día arranque mejor.',
  ),
  HabitTemplateOption(
    title: 'Registrar gasto del día',
    emoji: '💸',
    category: 'Finanzas',
    colorHex: '#7DD3A7',
    description: 'Anota en menos de un minuto lo que gastaste hoy.',
  ),
  HabitTemplateOption(
    title: 'Separar ahorro automático',
    emoji: '🏦',
    category: 'Finanzas',
    colorHex: '#5BC0A5',
    description: 'Mueve una pequeña cantidad a ahorro antes de gastar.',
  ),
  HabitTemplateOption(
    title: 'Escribir a alguien importante',
    emoji: '💬',
    category: 'Relaciones',
    colorHex: '#F1C7D8',
    description: 'Cuida vínculos con un gesto simple y consistente.',
  ),
  HabitTemplateOption(
    title: 'Preguntar cómo estuvo su día',
    emoji: '💌',
    category: 'Relaciones',
    colorHex: '#F4B6CC',
    description: 'Haz presente a alguien importante con una conversación corta.',
  ),
  HabitTemplateOption(
    title: 'Llamar a familia o amigo',
    emoji: '📞',
    category: 'Relaciones',
    colorHex: '#F5C3D8',
    description: 'Reserva unos minutos para sostener vínculos fuera del chat.',
  ),
];
