import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/clinical_form_scaffold.dart';
import '../../shared/widgets/form_section_card.dart';
import '../../shared/widgets/page_header.dart';
import '../patients/data/patient_lookup_data_source.dart';
import '../patients/widgets/patient_selector_field.dart';
import 'data/imaging_form_data_source.dart';
import 'data/imaging_repository.dart';
import 'models/imaging_note.dart';

class ImagingFormScreen extends StatefulWidget {
  final String? patientId;
  final bool isAssistant;
  const ImagingFormScreen({super.key, this.patientId, this.isAssistant = false});

  @override
  State<ImagingFormScreen> createState() => _ImagingFormScreenState();
}

class _ImagingFormScreenState extends State<ImagingFormScreen> {
  String? patientId;
  ImagingType? imagingType;
  ImagingBodyRegion? bodyRegion;
  ImagingSide? side;
  DateTime? imagingDate;
  final center = TextEditingController();
  final reportSummary = TextEditingController();
  final doctorComment = TextEditingController();
  final comparison = TextEditingController();
  final relatedDiagnosis = TextEditingController();
  final attachedFile = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    patientId = widget.patientId;
  }

  @override
  void dispose() {
    center.dispose();
    reportSummary.dispose();
    doctorComment.dispose();
    comparison.dispose();
    relatedDiagnosis.dispose();
    attachedFile.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => imagingDate = d);
  }

  Future<void> _save() async {
    if (_saving) return;

    if (patientId == null || patientId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hasta seçin.')),
      );
      return;
    }

    final patient = await PatientLookupDataSource.findById(patientId!);
    if (!mounted) return;
    if (patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen hasta seçin.')),
      );
      return;
    }

    final n = ImagingNote(
      id: 'i${DateTime.now().millisecondsSinceEpoch}',
      patientId: patient.id,
      patientName: patient.fullName,
      createdAt: DateTime.now(),
      imagingType: imagingType ?? ImagingType.diger,
      imagingDate: imagingDate ?? DateTime.now(),
      imagingCenter: center.text.trim(),
      bodyRegion: bodyRegion ?? ImagingBodyRegion.diger,
      side: side ?? ImagingSide.uygunDegil,
      reportSummary: reportSummary.text.trim(),
      doctorComment: doctorComment.text.trim(),
      comparisonWithPrevious: comparison.text.trim(),
      relatedDiagnosis: relatedDiagnosis.text.trim(),
      relatedVisitDate: null,
      attachedFileName: attachedFile.text.trim().isEmpty ? null : attachedFile.text.trim(),
    );

    setState(() => _saving = true);
    try {
      final saved = await ImagingFormDataSource.create(n);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görüntüleme notu kaydedildi')),
      );
      context.go('/imaging/${saved.id}');
    } on ImagingFormException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      setState(() => _saving = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görüntüleme notu kaydedilemedi.')),
      );
      setState(() => _saving = false);
    }
  }

  void _cancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.push('/imaging');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAssistant = widget.isAssistant;
    return ClinicalFormScaffold.sections(
      shellTitle: 'Yeni Görüntüleme Notu',
      onSave: _save,
      onCancel: _cancel,
      saveLabel: _saving ? 'Kaydediliyor...' : 'Kaydet',
      header: const PageHeader(
        title: 'Yeni Görüntüleme Notu',
        icon: Icons.image_search_outlined,
        leadingBack: true,
        fallbackRoute: '/imaging',
      ),
      sections: [
FormSectionCard(
                          title: 'Hasta ve Görüntüleme',
                          icon: Icons.medical_information_outlined,
                          children: [
                            PatientSelectorField(
                              selectedPatientId: patientId,
                              isDense: true,
                              onChanged: (v) => setState(() => patientId = v),
                            ),
                            DropdownButtonFormField<ImagingType>(
                              initialValue: imagingType,
                              decoration: const InputDecoration(
                                labelText: 'Görüntüleme Tipi',
                                isDense: true,
                              ),
                              isExpanded: true,
                              items: ImagingType.values
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        ImagingRepository.typeLabel(t),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => imagingType = v),
                            ),
                            LayoutBuilder(
                              builder: (context, rowConstraints) {
                                final stacked = rowConstraints.maxWidth < 480;
                                final regionField = DropdownButtonFormField<ImagingBodyRegion>(
                                  initialValue: bodyRegion,
                                  decoration: const InputDecoration(
                                    labelText: 'Bölge',
                                    isDense: true,
                                  ),
                                  isExpanded: true,
                                  items: ImagingBodyRegion.values
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(
                                            ImagingRepository.regionLabel(r),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() => bodyRegion = v),
                                );
                                final sideField = DropdownButtonFormField<ImagingSide>(
                                  initialValue: side,
                                  decoration: const InputDecoration(
                                    labelText: 'Taraf',
                                    isDense: true,
                                  ),
                                  isExpanded: true,
                                  items: ImagingSide.values
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            s.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() => side = v),
                                );
                                if (stacked) {
                                  return Column(
                                    children: [regionField, sideField],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: regionField),
                                    const SizedBox(width: 12),
                                    Expanded(child: sideField),
                                  ],
                                );
                              },
                            ),
                            LayoutBuilder(
                              builder: (context, rowConstraints) {
                                final stacked = rowConstraints.maxWidth < 420;
                                final dateLabel = imagingDate == null
                                    ? 'Görüntüleme tarihi seçilmedi'
                                    : 'Tarih: ${imagingDate!.toLocal().toString().split(' ').first}';
                                final dateRow = Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        dateLabel,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      onPressed: _pickDate,
                                      child: const Text('Tarih'),
                                    ),
                                  ],
                                );
                                final centerField = TextFormField(
                                  controller: center,
                                  decoration: const InputDecoration(
                                    labelText: 'Merkez',
                                    isDense: true,
                                  ),
                                );
                                if (stacked) {
                                  return Column(
                                    children: [dateRow, centerField],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 2, child: dateRow),
                                    const SizedBox(width: 12),
                                    Expanded(child: centerField),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        FormSectionCard(
                          title: 'Rapor ve Değerlendirme',
                          children: [
                            TextFormField(
                              controller: reportSummary,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Rapor Özeti',
                                isDense: true,
                              ),
                            ),
                            TextFormField(
                              controller: doctorComment,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Doktor Yorumu',
                                isDense: true,
                              ),
                              enabled: !isAssistant,
                            ),
                            TextFormField(
                              controller: comparison,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Önceki Görüntüleme ile Karşılaştırma',
                                isDense: true,
                              ),
                            ),
                            TextFormField(
                              controller: relatedDiagnosis,
                              decoration: const InputDecoration(
                                labelText: 'İlgili Tanı',
                                isDense: true,
                              ),
                            ),
                            TextFormField(
                              controller: attachedFile,
                              decoration: const InputDecoration(
                                labelText: 'Ekli Dosya Adı',
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
      ],
    );
  }
}
