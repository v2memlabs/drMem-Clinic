import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/layout/responsive_page_body.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/clinical_state_message.dart';
import '../../shared/widgets/page_header.dart';
import 'data/patient_alerts_data_source.dart';
import 'data/patient_alerts_load_result.dart';
import 'models/patient_alert.dart';

class PatientAlertsScreen extends StatefulWidget {
  final String? patientId;

  const PatientAlertsScreen({super.key, this.patientId});

  @override
  State<PatientAlertsScreen> createState() => _PatientAlertsScreenState();
}

class _PatientAlertsScreenState extends State<PatientAlertsScreen> {
  late Future<PatientAlertsLoadResult> _loadFuture;
  String search = '';
  AlertSeverity? severityFilter;
  PatientAlertType? typeFilter;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _loadFuture = PatientAlertsDataSource.load();
    });
  }

  List<PatientAlert> _filtered(List<PatientAlert> alerts) {
    final q = search.toLowerCase();
    return alerts.where((a) {
      if (widget.patientId != null &&
          widget.patientId!.isNotEmpty &&
          a.patientId != widget.patientId) {
        return false;
      }
      if (severityFilter != null && a.severity != severityFilter) return false;
      if (typeFilter != null && a.alertType != typeFilter) return false;
      if (q.isEmpty) return true;
      if (a.patientName.toLowerCase().contains(q)) return true;
      if (patientAlertTypeLabel(a.alertType).toLowerCase().contains(q)) {
        return true;
      }
      if (alertSeverityLabel(a.severity).toLowerCase().contains(q)) return true;
      if (a.title.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  Color _severityColor(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.dusuk:
        return Colors.blue;
      case AlertSeverity.orta:
        return Colors.orange;
      case AlertSeverity.yuksek:
        return Colors.deepOrange;
      case AlertSeverity.kritik:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Klinik Uyarılar',
      child: ResponsiveListPage(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const PageHeader(
                title: 'Klinik Uyarılar',
                subtitle: 'Ödeme, onam, kontrol ve FTR uyarıları',
                icon: Icons.warning_amber_outlined,
              ),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText:
                      'Hasta, uyarı tipi, önem derecesi veya başlığa göre ara',
                ),
                onChanged: (v) => setState(() => search = v),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  DropdownButton<AlertSeverity?>(
                    value: severityFilter,
                    hint: const Text('Önem'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tümü')),
                      ...AlertSeverity.values.map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(alertSeverityLabel(s)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => severityFilter = v),
                  ),
                  DropdownButton<PatientAlertType?>(
                    value: typeFilter,
                    hint: const Text('Uyarı tipi'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Tümü')),
                      ...PatientAlertType.values.map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(patientAlertTypeLabel(t)),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => typeFilter = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<PatientAlertsLoadResult>(
                  future: _loadFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ClinicalStateMessage.loading(
                        message: 'Klinik uyarılar yükleniyor…',
                      );
                    }

                    final result = snapshot.data;
                    if (result == null) {
                      return ClinicalStateMessage.error(
                        icon: Icons.error_outline,
                        title: 'Uyarılar yüklenemedi',
                        description: ClinicalStateMessage.safeErrorDescription(
                          snapshot.error?.toString(),
                        ),
                        onRetry: _reload,
                      );
                    }

                    if (result.isPartialError) {
                      // Kaynakların bir kısmı yüklenemedi; mevcut uyarılar gösterilir.
                    }

                    return _buildList(result.alerts);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<PatientAlert> alerts) {
    final list = _filtered(alerts);
    if (list.isEmpty) {
      return ClinicalStateMessage.empty(
        icon: Icons.check_circle_outline,
        title: 'Açık uyarı bulunmuyor',
        description: widget.patientId == null
            ? 'Operasyonel kaynaklarda bekleyen kayıt yok.'
            : 'Bu hasta için bekleyen kayıt yok.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            children: list.map((a) => _card(context, a)).toList(),
          );
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _card(context, list[index]),
        );
      },
    );
  }

  Widget _card(BuildContext context, PatientAlert a) {
    final dueStr = a.dueDate != null
        ? a.dueDate!.toLocal().toString().split(' ').first
        : '-';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    a.patientName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: const Text('Açık'),
                  backgroundColor: Colors.amber.shade100,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                Chip(
                  label: Text(patientAlertTypeLabel(a.alertType)),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(alertSeverityLabel(a.severity)),
                  backgroundColor: _severityColor(a.severity).withOpacity(0.2),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(a.title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(a.description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('Son tarih: $dueStr', style: Theme.of(context).textTheme.bodySmall),
            Text('Modül: ${a.relatedModule}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: a.actionRoute == null || a.actionRoute!.isEmpty
                    ? null
                    : () => context.push(a.actionRoute!),
                child: const Text('Kayda git'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
