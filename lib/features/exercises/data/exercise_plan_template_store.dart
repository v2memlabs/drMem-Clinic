import '../models/exercise_plan.dart';

class ExercisePlanTemplate {
  final String id;
  final String title;
  final ExercisePlanPhase phase;
  final String goal;
  final String exercisesText;
  final String homeInstructions;
  final String warnings;

  const ExercisePlanTemplate({
    required this.id,
    required this.title,
    required this.phase,
    required this.goal,
    required this.exercisesText,
    this.homeInstructions = '',
    this.warnings = '',
  });
}

/// Fizyoterapist tarafından oluşturulabilen yerel rehabilitasyon şablonları.
abstract final class ExercisePlanTemplateStore {
  static final List<ExercisePlanTemplate> _templates = [
    ExercisePlanTemplate(
      id: 'tpl-knee-early',
      title: 'Diz — Erken Rehabilitasyon',
      phase: ExercisePlanPhase.erkenRehabilitasyon,
      goal: 'Ağrı kontrolü, eklem hareket açıklığı ve quadriceps aktivasyonu',
      exercisesText:
          'Quadriceps izometrik\nHamstring esnetme\nAktif diz fleksiyon\nDenge tahtası üzerinde tek ayak',
      homeInstructions:
          'Günde 2 kez, ağrı artışı olursa durun. Buz 15 dk uygulayın.',
      warnings: 'Derin çömelme ve merdiven inişinden kaçının.',
    ),
    ExercisePlanTemplate(
      id: 'tpl-shoulder-early',
      title: 'Omuz — Erken Rehabilitasyon',
      phase: ExercisePlanPhase.erkenRehabilitasyon,
      goal: 'Omuz mobilitesi ve rotator cuff aktivasyonu',
      exercisesText:
          'Pendulum egzersizi\nKodman sallanma\nİzometrik dış rotasyon\nDuvar tırmanma',
      homeInstructions: 'Günde 2 set, ağrısız aralıkta uygulayın.',
      warnings: 'Ağrılı yükleme ve ani kaldırma yapmayın.',
    ),
  ];

  static List<ExercisePlanTemplate> listAll() =>
      List.unmodifiable(_templates);

  static void add(ExercisePlanTemplate template) {
    _templates.insert(0, template);
  }
}
