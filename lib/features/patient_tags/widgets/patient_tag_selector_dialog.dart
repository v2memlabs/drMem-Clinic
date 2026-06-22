import 'package:flutter/material.dart';

import '../../clinical_encounter/data/clinical_role_summary_ui_states.dart';
import '../data/patient_tag_list_user_messages.dart';
import '../data/patient_tag_module_availability.dart';
import '../data/patient_tag_repository_contract.dart';
import '../data/patient_tag_repository_provider.dart';
import '../models/patient_tag.dart';
import 'patient_tag_chip.dart';
import 'patient_tag_form_dialog.dart';

class PatientTagSelectorDialog extends StatefulWidget {
  final String patientId;

  const PatientTagSelectorDialog({super.key, required this.patientId});

  @override
  State<PatientTagSelectorDialog> createState() => _PatientTagSelectorDialogState();
}

class _PatientTagSelectorDialogState extends State<PatientTagSelectorDialog> {
  late Future<_SelectorData> _dataFuture;

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

  Future<_SelectorData> _load() async {
    if (!PatientTagModuleAvailability.isOperational) {
      throw const PatientTagRepositoryException(
        PatientTagRepositoryFailure.notConfigured,
        PatientTagListUserMessages.notConfigured,
      );
    }

    final repo = PatientTagRepositoryProvider.repository;
    final tags = await repo.listActive();
    final assignedIds = await repo.getTagIdsForPatient(widget.patientId);
    return _SelectorData(tags: tags, assignedIds: assignedIds);
  }

  Future<void> _createAndAssign() async {
    final created = await showDialog<PatientTag>(
      context: context,
      builder: (_) => const PatientTagFormDialog(),
    );
    if (created == null || !mounted) return;
    await PatientTagRepositoryProvider.repository.assignToPatient(
      patientId: widget.patientId,
      tagId: created.id,
    );
    _reload();
  }

  Future<void> _assign(String tagId) async {
    await PatientTagRepositoryProvider.repository.assignToPatient(
      patientId: widget.patientId,
      tagId: tagId,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Etiket Ekle'),
      content: SizedBox(
        width: 440,
        child: _buildContent(),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Tamam'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (!PatientTagModuleAvailability.isOperational) {
      return ClinicalRoleSummaryUiStates.listEmpty(
        icon: Icons.label_off_outlined,
        title: PatientTagListUserMessages.notConfigured,
        description: PatientTagListUserMessages.notConfiguredDescription,
      );
    }

    return FutureBuilder<_SelectorData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          if (error is PatientTagRepositoryException &&
              error.failure == PatientTagRepositoryFailure.notConfigured) {
            return ClinicalRoleSummaryUiStates.listEmpty(
              icon: Icons.label_off_outlined,
              title: PatientTagListUserMessages.notConfigured,
              description: PatientTagListUserMessages.notConfiguredDescription,
            );
          }
          return const Text(PatientTagListUserMessages.genericError);
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        final tags = data.tags;
        final assignedIds = data.assignedIds.toSet();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tags.isEmpty)
              const Text('Henüz tanımlı etiket yok. Yeni etiket oluşturun.')
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: tags.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    final assigned = assignedIds.contains(tag.id);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: PatientTagChip(tag: tag),
                      title: Text(
                        tag.description.isEmpty ? tag.name : tag.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: assigned
                          ? const Text('Atandı', style: TextStyle(fontSize: 12))
                          : null,
                      enabled: !assigned,
                      onTap: assigned ? null : () => _assign(tag.id),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _createAndAssign,
              icon: const Icon(Icons.add),
              label: const Text('Yeni Etiket Oluştur'),
            ),
          ],
        );
      },
    );
  }
}

class _SelectorData {
  final List<PatientTag> tags;
  final List<String> assignedIds;

  const _SelectorData({
    required this.tags,
    required this.assignedIds,
  });
}
