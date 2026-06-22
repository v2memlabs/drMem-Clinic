import 'package:flutter/material.dart';

import '../../settings/data/tenant_membership_repository_provider.dart';
import '../../settings/models/tenant_membership_user.dart';

class PhysiotherapistSelectorField extends StatefulWidget {
  final String? selectedProfileId;
  final ValueChanged<String?>? onChanged;
  final ValueChanged<TenantMembershipUser?>? onPhysiotherapistSelected;
  final bool enabled;

  const PhysiotherapistSelectorField({
    super.key,
    required this.selectedProfileId,
    this.onChanged,
    this.onPhysiotherapistSelected,
    this.enabled = true,
  });

  @override
  State<PhysiotherapistSelectorField> createState() =>
      _PhysiotherapistSelectorFieldState();
}

class _PhysiotherapistSelectorFieldState
    extends State<PhysiotherapistSelectorField> {
  late Future<List<TenantMembershipUser>> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadPhysiotherapists();
  }

  Future<List<TenantMembershipUser>> _loadPhysiotherapists() async {
    final members =
        await TenantMembershipRepositoryProvider.repository.listCurrentTenantMembers();
    return members
        .where((m) => m.isActivePhysiotherapist)
        .toList(growable: false);
  }

  String _memberId(TenantMembershipUser member) =>
      member.profileId.isNotEmpty ? member.profileId : member.membershipId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TenantMembershipUser>>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }

        final physiotherapists = snapshot.data ?? const [];
        if (physiotherapists.isEmpty) {
          return TextFormField(
            readOnly: true,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Fizyoterapist',
              isDense: true,
              helperText: 'Aktif fizyoterapist bulunamadı',
            ),
          );
        }

        final selectedId = widget.selectedProfileId;
        final validSelection = physiotherapists.any(
          (p) => _memberId(p) == selectedId,
        )
            ? selectedId
            : null;

        return DropdownButtonFormField<String>(
          value: validSelection,
          decoration: const InputDecoration(
            labelText: 'Fizyoterapist',
            isDense: true,
            helperText: 'Tek fizyoterapist varsa otomatik atanır',
          ),
          isExpanded: true,
          items: [
            for (final physio in physiotherapists)
              DropdownMenuItem(
                value: _memberId(physio),
                child: Text(
                  physio.displayName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Fizyoterapist seçin' : null,
          onChanged: !widget.enabled || widget.onChanged == null
              ? null
              : (value) {
                  widget.onChanged?.call(value);
                  TenantMembershipUser? selected;
                  for (final physio in physiotherapists) {
                    if (_memberId(physio) == value) {
                      selected = physio;
                      break;
                    }
                  }
                  widget.onPhysiotherapistSelected?.call(selected);
                },
        );
      },
    );
  }
}

/// Klinikteki aktif fizyoterapistleri yükler; tek kayıt varsa otomatik seçer.
abstract final class PhysiotherapistAssignmentResolver {
  static Future<({String? profileId, String? displayName})> resolveDefault() async {
    final members =
        await TenantMembershipRepositoryProvider.repository.listCurrentTenantMembers();
    final physiotherapists =
        members.where((m) => m.isActivePhysiotherapist).toList(growable: false);
    if (physiotherapists.length != 1) {
      return (profileId: null, displayName: null);
    }
    final only = physiotherapists.first;
    final profileId =
        only.profileId.isNotEmpty ? only.profileId : only.membershipId;
    return (profileId: profileId, displayName: only.displayName);
  }
}
