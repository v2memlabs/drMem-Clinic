import '../../../core/constants/app_roles.dart';

/// Klinik rol erişim anahtarları — [AuthSession] ile hizalı.
enum TenantRoleAccessKey {
  viewPatients,
  editPatients,
  viewAllAppointments,
  viewOwnScopedAppointments,
  editAppointments,
  selectAppointmentDoctor,
  startAnamnesis,
  editAnamnesis,
  viewClinicalEncounters,
  editClinicalEncounters,
  viewClinicalDiagnosisSummary,
  viewAnamnesisDetails,
  viewExaminationDetails,
  viewTreatmentPlanDetails,
  viewClinicalSummary,
  viewClinicalDiagnosis,
  viewClinicalTreatmentPlan,
  editExaminationNotes,
  editDiagnosis,
  editTreatmentPlans,
  viewImaging,
  editImaging,
  viewPdfOutputs,
  editPdfOutputs,
  viewPrescriptions,
  editPrescriptions,
  viewClinicalReports,
  editClinicalReports,
  viewRadiologyOrders,
  editRadiologyOrders,
  viewLabOrders,
  editLabOrders,
  manageLabOrderTemplates,
  viewAuditLogs,
  viewSurgeryNotes,
  editSurgeryNotes,
  viewPatientTimeline,
  viewFiles,
  editFiles,
  viewConsents,
  editConsents,
  viewConsentTemplates,
  viewPayments,
  createPayments,
  editPayments,
  chargePatientMaterials,
  viewMessages,
  viewMessageTemplates,
  viewPhysiotherapy,
  editPhysiotherapy,
  viewExercisePlans,
  editExercisePlans,
  viewPostOpProtocols,
  editPostOpProtocols,
  viewInventory,
  editInventory,
  recordInventoryMovement,
  viewPatientAlerts,
  viewPatientTags,
  createPatientTags,
  assignPatientTags,
  removePatientTags,
  approveStaffLeave,
  viewDoctorOnlySettings,
  editClinicProfile,
}

class TenantRoleAccessDefinition {
  final TenantRoleAccessKey key;
  final String label;
  final String description;

  const TenantRoleAccessDefinition({
    required this.key,
    required this.label,
    required this.description,
  });
}

abstract final class TenantRoleAccessCatalog {
  static const roles = [
    AppRoles.doctor,
    AppRoles.assistant,
    AppRoles.physiotherapist,
    AppRoles.nurse,
  ];

  static const definitions = <TenantRoleAccessDefinition>[
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewPatients,
      label: 'Hasta görüntüleme',
      description: 'Hasta listesi ve detay ekranları.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editPatients,
      label: 'Hasta düzenleme',
      description: 'Yeni hasta ve hasta bilgisi güncelleme.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewAllAppointments,
      label: 'Tüm randevular',
      description: 'Klinik genelinde randevu listesi.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewOwnScopedAppointments,
      label: 'Kendi randevuları',
      description: 'Yalnızca kendine atanmış randevular.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editAppointments,
      label: 'Randevu oluşturma / düzenleme',
      description: 'Yeni randevu ve randevu güncelleme.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.selectAppointmentDoctor,
      label: 'Randevu doktoru seçimi',
      description: 'Randevu formunda doktor atama.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.startAnamnesis,
      label: 'Anamnez başlatma',
      description: 'Yeni anamnez kaydı oluşturma.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editAnamnesis,
      label: 'Anamnez düzenleme',
      description: 'Anamnez kayıtlarını güncelleme.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewClinicalEncounters,
      label: 'Muayene kayıtları',
      description: 'Tam muayene kayıtlarına erişim.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editClinicalEncounters,
      label: 'Muayene kaydı düzenleme',
      description: 'Muayene kaydı oluşturma ve güncelleme.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewClinicalDiagnosisSummary,
      label: 'Tanı özeti',
      description: 'Operasyonel tanı özeti ekranı.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewSurgeryNotes,
      label: 'Ameliyat notları',
      description: 'Ameliyat / girişim notları listesi ve detay.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editSurgeryNotes,
      label: 'Ameliyat notu düzenleme',
      description: 'Ameliyat / girişim notu oluşturma ve düzenleme.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewPdfOutputs,
      label: 'PDF çıktıları',
      description: 'PDF listesi, hazırlama ve yazdırma.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editPdfOutputs,
      label: 'PDF düzenleme',
      description: 'PDF oluşturma, kaydetme ve yazdırma.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewPostOpProtocols,
      label: 'Post-op protokolleri',
      description: 'Post-op protokol listesi ve detay.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editPostOpProtocols,
      label: 'Post-op protokol düzenleme',
      description: 'Post-op protokol oluşturma.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewPhysiotherapy,
      label: 'Fizyoterapi',
      description: 'Fizyoterapi modülüne erişim.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editPhysiotherapy,
      label: 'Fizyoterapi düzenleme',
      description: 'Fizyoterapi kayıtlarını düzenleme.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewInventory,
      label: 'Stok görüntüleme',
      description: 'Stok listesi ve hareketler.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editInventory,
      label: 'Stok düzenleme',
      description: 'Stok kayıtlarını güncelleme.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewRadiologyOrders,
      label: 'Radyoloji istemleri',
      description: 'Radyoloji istem listesi.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editRadiologyOrders,
      label: 'Radyoloji istemi düzenleme',
      description: 'Radyoloji istemi oluşturma / güncelleme.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewLabOrders,
      label: 'Laboratuvar istemleri',
      description: 'Lab istem listesi.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editLabOrders,
      label: 'Lab istemi düzenleme',
      description: 'Lab istemi oluşturma / güncelleme.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewFiles,
      label: 'Dosyalar',
      description: 'Hasta dosyalarına erişim.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editFiles,
      label: 'Dosya yükleme',
      description: 'Hasta dosyası yükleme.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewConsents,
      label: 'Onamlar',
      description: 'Onam kayıtlarına erişim.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editConsents,
      label: 'Onam düzenleme',
      description: 'Onam oluşturma / güncelleme.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewPayments,
      label: 'Ödemeler',
      description: 'Ödeme kayıtlarına erişim (finans bayrağı ile birlikte).',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.createPayments,
      label: 'Ödeme kaydı oluşturma',
      description: 'Yeni ödeme / tahsilat kaydı ekleme.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editPayments,
      label: 'Ödeme kaydı düzenleme',
      description: 'Mevcut ödeme kayıtlarını güncelleme.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewAuditLogs,
      label: 'Audit kayıtları',
      description: 'Denetim günlüklerine erişim.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.viewPatientTimeline,
      label: 'Hasta zaman çizelgesi',
      description: 'Hasta timeline ekranı.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.approveStaffLeave,
      label: 'İzin onayı',
      description: 'Personel izin taleplerini onaylama.',
    ),
    TenantRoleAccessDefinition(
      key: TenantRoleAccessKey.editClinicProfile,
      label: 'Klinik profili düzenleme',
      description: 'Klinik bilgileri ve yönetici ayarları.',
    ),
  ];
}

abstract final class TenantRoleAccessDefaults {
  static const _doctor = {AppRoles.doctor};
  static const _assistant = {AppRoles.assistant};
  static const _physio = {AppRoles.physiotherapist};
  static const _nurse = {AppRoles.nurse};
  static const _doctorAssistant = {AppRoles.doctor, AppRoles.assistant};
  static const _doctorPhysio = {AppRoles.doctor, AppRoles.physiotherapist};
  static const _doctorNurse = {AppRoles.doctor, AppRoles.nurse};
  static const _assistantNurse = {AppRoles.assistant, AppRoles.nurse};
  static const _allClinical = {
    AppRoles.doctor,
    AppRoles.assistant,
    AppRoles.physiotherapist,
    AppRoles.nurse,
  };
  static const _doctorAssistantPhysio = {
    AppRoles.doctor,
    AppRoles.assistant,
    AppRoles.physiotherapist,
  };
  static const _doctorAssistantNurse = {
    AppRoles.doctor,
    AppRoles.assistant,
    AppRoles.nurse,
  };
  static const _doctorAssistantPhysioNurse = {
    AppRoles.doctor,
    AppRoles.assistant,
    AppRoles.physiotherapist,
    AppRoles.nurse,
  };

  static bool forRole(String role, TenantRoleAccessKey key) {
    return _matrix[key]?.contains(role) ?? false;
  }

  static Map<TenantRoleAccessKey, bool> forRoleMap(String role) {
    return {
      for (final def in TenantRoleAccessCatalog.definitions)
        def.key: forRole(role, def.key),
    };
  }

  static final Map<TenantRoleAccessKey, Set<String>> _matrix = {
    TenantRoleAccessKey.viewPatients: _allClinical,
    TenantRoleAccessKey.editPatients: _doctorAssistant,
    TenantRoleAccessKey.viewAllAppointments: _assistantNurse,
    TenantRoleAccessKey.viewOwnScopedAppointments: _doctorPhysio,
    TenantRoleAccessKey.editAppointments: _doctorAssistantNurse,
    TenantRoleAccessKey.selectAppointmentDoctor: _assistantNurse,
    TenantRoleAccessKey.startAnamnesis: _doctorAssistant,
    TenantRoleAccessKey.editAnamnesis: _doctor,
    TenantRoleAccessKey.viewClinicalEncounters: _doctor,
    TenantRoleAccessKey.editClinicalEncounters: _doctor,
    TenantRoleAccessKey.viewClinicalDiagnosisSummary: _doctorAssistant,
    TenantRoleAccessKey.viewAnamnesisDetails: _doctor,
    TenantRoleAccessKey.viewExaminationDetails: _doctor,
    TenantRoleAccessKey.viewTreatmentPlanDetails: _doctor,
    TenantRoleAccessKey.viewClinicalSummary: _doctorPhysio,
    TenantRoleAccessKey.viewClinicalDiagnosis: _doctorPhysio,
    TenantRoleAccessKey.viewClinicalTreatmentPlan: _doctorPhysio,
    TenantRoleAccessKey.editExaminationNotes: _doctor,
    TenantRoleAccessKey.editDiagnosis: _doctor,
    TenantRoleAccessKey.editTreatmentPlans: _doctor,
    TenantRoleAccessKey.viewImaging: _doctor,
    TenantRoleAccessKey.editImaging: _doctor,
    TenantRoleAccessKey.viewPdfOutputs: _doctorAssistant,
    TenantRoleAccessKey.editPdfOutputs: _doctorAssistant,
    TenantRoleAccessKey.viewPrescriptions: _doctorAssistant,
    TenantRoleAccessKey.editPrescriptions: _doctor,
    TenantRoleAccessKey.viewClinicalReports: _doctorAssistant,
    TenantRoleAccessKey.editClinicalReports: _doctor,
    TenantRoleAccessKey.viewRadiologyOrders: _doctorAssistant,
    TenantRoleAccessKey.editRadiologyOrders: _doctor,
    TenantRoleAccessKey.viewLabOrders: _doctorAssistantNurse,
    TenantRoleAccessKey.editLabOrders: _doctorAssistantNurse,
    TenantRoleAccessKey.manageLabOrderTemplates: _doctorAssistantNurse,
    TenantRoleAccessKey.viewAuditLogs: _doctor,
    TenantRoleAccessKey.viewSurgeryNotes: _doctor,
    TenantRoleAccessKey.editSurgeryNotes: _doctor,
    TenantRoleAccessKey.viewPatientTimeline: _doctor,
    TenantRoleAccessKey.viewFiles: _doctorAssistant,
    TenantRoleAccessKey.editFiles: _doctorAssistant,
    TenantRoleAccessKey.viewConsents: _doctorAssistant,
    TenantRoleAccessKey.editConsents: _doctorAssistant,
    TenantRoleAccessKey.viewConsentTemplates: _doctorAssistant,
    TenantRoleAccessKey.viewPayments: _doctorAssistantPhysio,
    TenantRoleAccessKey.createPayments: _doctorAssistantPhysio,
    TenantRoleAccessKey.editPayments: _doctorAssistantPhysio,
    TenantRoleAccessKey.chargePatientMaterials: _doctorAssistantPhysioNurse,
    TenantRoleAccessKey.viewMessages: _doctorAssistant,
    TenantRoleAccessKey.viewMessageTemplates: _doctor,
    TenantRoleAccessKey.viewPhysiotherapy: _doctorPhysio,
    TenantRoleAccessKey.editPhysiotherapy: _doctorPhysio,
    TenantRoleAccessKey.viewExercisePlans: _doctorPhysio,
    TenantRoleAccessKey.editExercisePlans: _doctorPhysio,
    TenantRoleAccessKey.viewPostOpProtocols: _doctorPhysio,
    TenantRoleAccessKey.editPostOpProtocols: _doctor,
    TenantRoleAccessKey.viewInventory: _doctorNurse,
    TenantRoleAccessKey.editInventory: _doctorNurse,
    TenantRoleAccessKey.recordInventoryMovement: _doctorNurse,
    TenantRoleAccessKey.viewPatientAlerts: _doctorAssistant,
    TenantRoleAccessKey.viewPatientTags: _doctorAssistantPhysio,
    TenantRoleAccessKey.createPatientTags: _doctorAssistant,
    TenantRoleAccessKey.assignPatientTags: _doctorAssistant,
    TenantRoleAccessKey.removePatientTags: _doctorAssistant,
    TenantRoleAccessKey.approveStaffLeave: _doctor,
    TenantRoleAccessKey.viewDoctorOnlySettings: _doctor,
    TenantRoleAccessKey.editClinicProfile: _doctor,
  };
}

class TenantRoleAccessSettings {
  final Map<String, Map<TenantRoleAccessKey, bool>> overridesByRole;

  const TenantRoleAccessSettings({required this.overridesByRole});

  static TenantRoleAccessSettings empty() =>
      const TenantRoleAccessSettings(overridesByRole: {});

  bool isAllowed(String role, TenantRoleAccessKey key) {
    final roleOverrides = overridesByRole[role];
    if (roleOverrides != null && roleOverrides.containsKey(key)) {
      return roleOverrides[key]!;
    }
    return TenantRoleAccessDefaults.forRole(role, key);
  }

  TenantRoleAccessSettings copyWithFlag(
    String role,
    TenantRoleAccessKey key,
    bool enabled,
  ) {
    final nextRole = Map<TenantRoleAccessKey, bool>.from(
      overridesByRole[role] ?? const {},
    );
    nextRole[key] = enabled;
    final next = Map<String, Map<TenantRoleAccessKey, bool>>.from(overridesByRole);
    next[role] = nextRole;
    return TenantRoleAccessSettings(overridesByRole: next);
  }

  Map<String, dynamic> toJson() {
    final out = <String, dynamic>{};
    for (final role in TenantRoleAccessCatalog.roles) {
      final roleMap = <String, bool>{};
      for (final def in TenantRoleAccessCatalog.definitions) {
        roleMap[_storageKey(def.key)] = isAllowed(role, def.key);
      }
      out[role] = roleMap;
    }
    return out;
  }

  static TenantRoleAccessSettings fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return empty();
    final nested = json['role_access'];
    final source = nested is Map<String, dynamic> ? nested : json;
    final overrides = <String, Map<TenantRoleAccessKey, bool>>{};

    for (final role in TenantRoleAccessCatalog.roles) {
      final rawRole = source[role];
      if (rawRole is! Map) continue;
      final roleOverrides = <TenantRoleAccessKey, bool>{};
      for (final def in TenantRoleAccessCatalog.definitions) {
        final raw = rawRole[_storageKey(def.key)];
        if (raw is! bool) continue;
        final defaultValue = TenantRoleAccessDefaults.forRole(role, def.key);
        if (raw != defaultValue) {
          roleOverrides[def.key] = raw;
        }
      }
      if (roleOverrides.isNotEmpty) {
        overrides[role] = roleOverrides;
      }
    }

    return TenantRoleAccessSettings(overridesByRole: overrides);
  }

  static String _storageKey(TenantRoleAccessKey key) {
    return key.name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
  }

  static TenantRoleAccessKey? _keyFromStorage(String raw) {
    final normalized = raw.trim();
    for (final key in TenantRoleAccessKey.values) {
      if (_storageKey(key) == normalized) return key;
    }
    return null;
  }

  static TenantRoleAccessSettings parseRoleAccessJson(Map<String, dynamic> json) {
    final overrides = <String, Map<TenantRoleAccessKey, bool>>{};
    for (final role in TenantRoleAccessCatalog.roles) {
      final rawRole = json[role];
      if (rawRole is! Map) continue;
      final roleOverrides = <TenantRoleAccessKey, bool>{};
      rawRole.forEach((k, v) {
        if (v is! bool) return;
        final key = _keyFromStorage(k.toString());
        if (key == null) return;
        final defaultValue = TenantRoleAccessDefaults.forRole(role, key);
        if (v != defaultValue) {
          roleOverrides[key] = v;
        }
      });
      if (roleOverrides.isNotEmpty) {
        overrides[role] = roleOverrides;
      }
    }
    return TenantRoleAccessSettings(overridesByRole: overrides);
  }
}
