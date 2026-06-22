import 'package:flutter/material.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/session/record_ownership_context.dart';
import '../../settings/data/tenant_membership_repository_provider.dart';
import '../../settings/models/tenant_membership_user.dart';

class DoctorSelectorField extends StatefulWidget {
  final String? selectedDoctorProfileId;
  final ValueChanged<String?>? onChanged;
  final ValueChanged<TenantMembershipUser?>? onDoctorSelected;
  final bool readOnly;
  final bool enabled;

  const DoctorSelectorField({
    super.key,
    required this.selectedDoctorProfileId,
    this.onChanged,
    this.onDoctorSelected,
    this.readOnly = false,
    this.enabled = true,
  });

  @override
  State<DoctorSelectorField> createState() => _DoctorSelectorFieldState();
}

class _DoctorSelectorFieldState extends State<DoctorSelectorField> {
  late Future<List<TenantMembershipUser>> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadDoctors();
  }

  Future<List<TenantMembershipUser>> _loadDoctors() async {
    final members =
        await TenantMembershipRepositoryProvider.repository.listCurrentTenantMembers();
    return members.where((m) => m.isActiveDoctorAdmin).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.canSelectAppointmentDoctor) {
      return TextFormField(
        readOnly: true,
        enabled: false,
        initialValue: RecordOwnershipContext.currentDisplayName(),
        decoration: const InputDecoration(
          labelText: 'Doktor',
          isDense: true,
          helperText: 'Randevu oturumdaki doktora kaydedilir',
        ),
      );
    }

    return FutureBuilder<List<TenantMembershipUser>>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }

        final doctors = snapshot.data ?? const [];
        if (doctors.isEmpty) {
          return TextFormField(
            readOnly: true,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Doktor',
              isDense: true,
              helperText: 'Aktif doktor bulunamadı',
            ),
          );
        }

        final selectedId = widget.selectedDoctorProfileId;
        final validSelection = doctors.any(
          (d) => d.profileId.isNotEmpty && d.profileId == selectedId,
        )
            ? selectedId
            : null;

        return DropdownButtonFormField<String>(
          value: validSelection,
          decoration: InputDecoration(
            labelText: 'Doktor',
            isDense: true,
            helperText: widget.readOnly ? 'Doktor değiştirilemez' : null,
          ),
          isExpanded: true,
          items: [
            for (final doctor in doctors)
              DropdownMenuItem(
                value: doctor.profileId.isNotEmpty ? doctor.profileId : doctor.membershipId,
                child: Text(
                  doctor.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: widget.readOnly || !widget.enabled || widget.onChanged == null
              ? null
              : (value) {
                  widget.onChanged?.call(value);
                  TenantMembershipUser? selected;
                  for (final doctor in doctors) {
                    final id = doctor.profileId.isNotEmpty
                        ? doctor.profileId
                        : doctor.membershipId;
                    if (id == value) {
                      selected = doctor;
                      break;
                    }
                  }
                  widget.onDoctorSelected?.call(selected);
                },
        );
      },
    );
  }
}
