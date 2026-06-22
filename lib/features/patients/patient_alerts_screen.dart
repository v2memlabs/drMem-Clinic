import 'package:flutter/material.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/page_header.dart';
import 'data/mock_patient_alerts.dart';
import 'models/patient_alert.dart';

class PatientAlertsScreen extends StatefulWidget {
  final String? patientId;

  const PatientAlertsScreen({super.key, this.patientId});

  @override
  State<PatientAlertsScreen> createState() => _PatientAlertsScreenState();
}

class _PatientAlertsScreenState extends State<PatientAlertsScreen> {
  String search = '';
  AlertSeverity? severityFilter;
  PatientAlertType? typeFilter;
  bool? resolvedFilter;

  List<PatientAlert> get filtered {
    final q = search.toLowerCase();
    return mockPatientAlerts.where((a) {
      if (widget.patientId != null &&
          widget.patientId!.isNotEmpty &&
          a.patientId != widget.patientId) {
        return false;
      }
      if (severityFilter != null && a.severity != severityFilter) return false;
      if (typeFilter != null && a.alertType != typeFilter) return false;
      if (resolvedFilter != null && a.isResolved != resolvedFilter) return false;
      if (q.isEmpty) return true;
      if (a.patientName.toLowerCase().contains(q)) return true;
      if (patientAlertTypeLabel(a.alertType).toLowerCase().contains(q)) return true;
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const PageHeader(
              title: 'Klinik Uyarılar',
              subtitle: 'Kontrol ve eksik kayıt uyarıları',
              icon: Icons.warning_amber_outlined,
            ),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Hasta, uyarı tipi, önem derecesi veya başlığa göre ara',
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
                DropdownButton<bool?>(
                  value: resolvedFilter,
                  hint: const Text('Durum'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tümü')),
                    DropdownMenuItem(value: false, child: Text('Açık')),
                    DropdownMenuItem(value: true, child: Text('Çözüldü')),
                  ],
                  onChanged: (v) => setState(() => resolvedFilter = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final list = filtered;
                  if (list.isEmpty) {
                    return const Center(child: Text('Uyarı bulunamadı'));
                  }
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
              ),
            ),
          ],
        ),
      ),
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
                  child: Text(a.patientName, style: Theme.of(context).textTheme.titleMedium),
                ),
                Chip(
                  label: Text(a.isResolved ? 'Çözüldü' : 'Açık'),
                  backgroundColor: a.isResolved ? Colors.green.shade100 : Colors.amber.shade100,
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
                onPressed: a.isResolved
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${a.title} çözüldü olarak işaretlendi (mock)')),
                        );
                      },
                child: const Text('Çözüldü İşaretle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
