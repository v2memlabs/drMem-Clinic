import 'package:flutter/material.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/theme/app_spacing.dart';
import '../../clinical_encounter/data/clinical_role_summary_ui_states.dart';
import '../../patients/data/patient_lookup_data_source.dart';
import '../data/patient_tag_list_user_messages.dart';
import '../data/patient_tag_module_availability.dart';
import '../data/patient_tag_repository_contract.dart';
import '../data/patient_tag_repository_provider.dart';
import '../models/patient_tag.dart';
import 'patient_tag_chip.dart';
import 'patient_tag_form_dialog.dart';

/// Hasta etiket listesi — Ayarlar veya `/patient-tags` route içinde kullanılır.
class PatientTagListContent extends StatefulWidget {
  const PatientTagListContent({super.key});

  @override
  State<PatientTagListContent> createState() => _PatientTagListContentState();
}

class _PatientTagListContentState extends State<PatientTagListContent> {
  late Future<List<PatientTag>> _tagsFuture;
  final Map<String, int> _usageCache = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _tagsFuture = _loadTags();
    });
  }

  Future<List<PatientTag>> _loadTags() async {
    if (!PatientTagModuleAvailability.isOperational) {
      throw const PatientTagRepositoryException(
        PatientTagRepositoryFailure.notConfigured,
        PatientTagListUserMessages.notConfigured,
      );
    }

    final repo = PatientTagRepositoryProvider.repository;
    final tags = await repo.listAll();
    _usageCache.clear();
    if (PatientTagRepositoryProvider.usesRemote) {
      for (final tag in tags) {
        _usageCache[tag.id] = await repo.countPatientsWithTag(tag.id);
      }
    }
    return tags;
  }

  Future<void> _createTag() async {
    final created = await showDialog<PatientTag>(
      context: context,
      builder: (_) => const PatientTagFormDialog(),
    );
    if (created != null && mounted) {
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${created.name}" etiketi oluşturuldu.')),
      );
    }
  }

  int _usageFor(PatientTag tag) {
    if (PatientTagRepositoryProvider.usesRemote) {
      return _usageCache[tag.id] ?? 0;
    }
    return PatientLookupDataSource.countPatientsWithTagSync(tag.id);
  }

  Widget _notConfiguredBody() {
    return ClinicalRoleSummaryUiStates.listEmpty(
      icon: Icons.label_off_outlined,
      title: PatientTagListUserMessages.notConfigured,
      description: PatientTagListUserMessages.notConfiguredDescription,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!PatientTagModuleAvailability.isOperational) {
      return _notConfiguredBody();
    }

    final canCreate = AuthSession.canCreatePatientTags;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canCreate)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _createTag,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Yeni Etiket'),
              ),
            ),
          ),
        Expanded(
          child: FutureBuilder<List<PatientTag>>(
            future: _tagsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ClinicalRoleSummaryUiStates.listLoading(
                  message: PatientTagListUserMessages.loading,
                );
              }
              if (snapshot.hasError) {
                final error = snapshot.error;
                if (error is PatientTagRepositoryException &&
                    error.failure == PatientTagRepositoryFailure.notConfigured) {
                  return _notConfiguredBody();
                }
                return ClinicalRoleSummaryUiStates.listEmpty(
                  icon: Icons.error_outline,
                  title: PatientTagListUserMessages.errorTitle,
                  description: PatientTagListUserMessages.genericError,
                );
              }
              final tags = snapshot.data ?? const [];
              if (tags.isEmpty) {
                return ClinicalRoleSummaryUiStates.listEmpty(
                  icon: Icons.label_outline,
                  title: 'Tanımlı etiket bulunamadı.',
                  description: '',
                );
              }
              return ListView.separated(
                itemCount: tags.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => _tagCard(context, tags[index], muted),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _tagCard(BuildContext context, PatientTag tag, Color muted) {
    final usage = _usageFor(tag);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PatientTagChip(tag: tag),
                const Spacer(),
                Text(
                  tag.isActive ? 'Aktif' : 'Pasif',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tag.isActive ? Colors.green.shade700 : muted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            if (tag.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                tag.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kullanım: $usage hasta',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
