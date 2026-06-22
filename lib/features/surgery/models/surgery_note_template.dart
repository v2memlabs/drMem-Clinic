import 'surgery_procedure_note.dart';

class SurgeryNoteTemplate {
  final String id;
  final String profileId;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final SurgeryNoteTemplateContent content;

  const SurgeryNoteTemplate({
    required this.id,
    required this.profileId,
    required this.name,
    this.description = '',
    required this.createdAt,
    this.updatedAt,
    required this.content,
  });
}

class SurgeryNoteTemplateContent {
  final ProcedureType? procedureType;
  final SurgeryBodyRegion? bodyRegion;
  final SurgerySide? side;
  final String? asaScore;
  final bool? tourniquetUsed;
  final String diagnosis;
  final String procedureName;
  final String anesthesiaType;
  final String procedureDetails;
  final String complications;
  final String assistantInfo;
  final List<String> implantLines;
  final String postOpRecommendations;
  final String physiotherapyStartRecommendation;
  final String controlSchedule;
  final String notes;

  const SurgeryNoteTemplateContent({
    this.procedureType,
    this.bodyRegion,
    this.side,
    this.asaScore,
    this.tourniquetUsed,
    this.diagnosis = '',
    this.procedureName = '',
    this.anesthesiaType = '',
    this.procedureDetails = '',
    this.complications = '',
    this.assistantInfo = '',
    this.implantLines = const [],
    this.postOpRecommendations = '',
    this.physiotherapyStartRecommendation = '',
    this.controlSchedule = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      if (procedureType != null) 'procedureType': procedureType!.name,
      if (bodyRegion != null) 'bodyRegion': bodyRegion!.name,
      if (side != null) 'side': side!.name,
      if (asaScore != null) 'asaScore': asaScore,
      if (tourniquetUsed != null) 'tourniquetUsed': tourniquetUsed,
      'diagnosis': diagnosis,
      'procedureName': procedureName,
      'anesthesiaType': anesthesiaType,
      'procedureDetails': procedureDetails,
      'complications': complications,
      'assistantInfo': assistantInfo,
      'implantLines': implantLines,
      'postOpRecommendations': postOpRecommendations,
      'physiotherapyStartRecommendation': physiotherapyStartRecommendation,
      'controlSchedule': controlSchedule,
      'notes': notes,
    };
  }

  factory SurgeryNoteTemplateContent.fromJson(Map<String, dynamic> json) {
    return SurgeryNoteTemplateContent(
      procedureType: _enumOrNull(ProcedureType.values, json['procedureType']),
      bodyRegion: _enumOrNull(SurgeryBodyRegion.values, json['bodyRegion']),
      side: _enumOrNull(SurgerySide.values, json['side']),
      asaScore: json['asaScore']?.toString(),
      tourniquetUsed: json['tourniquetUsed'] as bool?,
      diagnosis: json['diagnosis']?.toString() ?? '',
      procedureName: json['procedureName']?.toString() ?? '',
      anesthesiaType: json['anesthesiaType']?.toString() ?? '',
      procedureDetails: json['procedureDetails']?.toString() ?? '',
      complications: json['complications']?.toString() ?? '',
      assistantInfo: json['assistantInfo']?.toString() ?? '',
      implantLines: _stringList(json['implantLines']),
      postOpRecommendations: json['postOpRecommendations']?.toString() ?? '',
      physiotherapyStartRecommendation:
          json['physiotherapyStartRecommendation']?.toString() ?? '',
      controlSchedule: json['controlSchedule']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }

  static T? _enumOrNull<T extends Enum>(List<T> values, Object? raw) {
    final name = raw?.toString().trim();
    if (name == null || name.isEmpty) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
  }
}
