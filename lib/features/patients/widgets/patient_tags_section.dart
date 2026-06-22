import 'package:flutter/material.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/data/repository_registry.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../patient_tags/data/patient_tag_repository_provider.dart';
import '../../patient_tags/models/patient_tag.dart';
import '../../patient_tags/widgets/patient_tag_chip.dart';
import '../../patient_tags/widgets/patient_tag_selector_dialog.dart';
import 'patient_premium_surfaces.dart';

class PatientTagsSection extends StatefulWidget {
  final String patientId;

  const PatientTagsSection({super.key, required this.patientId});

  @override
  State<PatientTagsSection> createState() => _PatientTagsSectionState();
}

class _PatientTagsSectionState extends State<PatientTagsSection> {
  late Future<_TagsSectionData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _dataFuture = _load();
    });
  }

  Future<_TagsSectionData> _load() async {
    final patient = await RepositoryRegistry.patientsAsync.getById(widget.patientId);
    if (patient == null) {
      return const _TagsSectionData(tags: []);
    }
    final tags = await PatientTagRepositoryProvider.repository
        .getByIds(patient.tagIds);
    return _TagsSectionData(tags: tags);
  }

  Future<void> _openSelector() async {
    await showDialog<bool>(
      context: context,
      builder: (_) => PatientTagSelectorDialog(patientId: widget.patientId),
    );
    if (mounted) _reload();
  }

  Future<void> _removeTag(String tagId) async {
    await PatientTagRepositoryProvider.repository.removeFromPatient(
      patientId: widget.patientId,
      tagId: tagId,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final canAssign = AuthSession.canAssignPatientTags;
    final canRemove = AuthSession.canRemovePatientTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PatientPremiumSurfaces.sectionHeader(
          context,
          title: 'Etiketler',
          icon: Icons.label_outline,
          trailing: canAssign
              ? TextButton.icon(
                  onPressed: _openSelector,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Etiket Ekle'),
                )
              : null,
        ),
        FutureBuilder<_TagsSectionData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            final tags = snapshot.data?.tags ?? const <PatientTag>[];
            return Container(
              decoration: PatientPremiumSurfaces.card(),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: tags.isEmpty
                  ? Text(
                      'Bu hastaya henüz etiket eklenmemiş.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    )
                  : Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: tags
                          .map(
                            (tag) => PatientTagChip(
                              tag: tag,
                              onRemove:
                                  canRemove ? () => _removeTag(tag.id) : null,
                            ),
                          )
                          .toList(),
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _TagsSectionData {
  final List<PatientTag> tags;

  const _TagsSectionData({required this.tags});
}
