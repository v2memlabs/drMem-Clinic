class ExerciseItem {
  final String id;
  final String name;
  final String description;
  final int repetitions;
  final int sets;
  final String duration;
  final String frequency;
  final String precautions;
  final String notes;

  ExerciseItem({
    required this.id,
    required this.name,
    required this.description,
    this.repetitions = 10,
    this.sets = 3,
    this.duration = '',
    this.frequency = '',
    this.precautions = '',
    this.notes = '',
  });
}
