import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../features/clinical_reports/data/clinical_report_lookup_data_source.dart';
import '../../../features/clinical_reports/data/clinical_report_pdf_patient_identity.dart';
import '../../../features/clinical_reports/services/clinical_report_pdf_generator.dart';
import '../../../features/lab_orders/data/lab_order_lookup_data_source.dart';
import '../../../features/lab_orders/models/lab_order.dart';
import '../../../features/lab_orders/services/lab_order_pdf_generator.dart';
import '../../../features/pdf_outputs/data/clinical_pdf_patient_identity.dart';
import '../../../features/patients/data/patient_lookup_data_source.dart';
import '../../../features/prescriptions/data/prescription_lookup_data_source.dart';
import '../../../features/prescriptions/services/prescription_pdf_generator.dart';
import '../../../features/radiology_orders/data/radiology_order_lookup_data_source.dart';
import '../../../features/radiology_orders/services/radiology_order_pdf_generator.dart';
import '../data/clinical_encounter_lookup_data_source.dart';
import '../models/clinical_encounter.dart';
import 'models/post_encounter_document_kind.dart';

abstract final class PostEncounterPrintService {
  static Future<void> printDocument({
    required PostEncounterDocumentKind kind,
    required String documentId,
  }) async {
    switch (kind) {
      case PostEncounterDocumentKind.clinicalReport:
        await _printClinicalReport(documentId);
      case PostEncounterDocumentKind.prescription:
        await _printPrescription(documentId);
      case PostEncounterDocumentKind.lab:
        await _printLabOrder(documentId);
      case PostEncounterDocumentKind.radiology:
        await _printRadiologyOrder(documentId);
    }
  }

  static Future<void> _printClinicalReport(String id) async {
    final report = await ClinicalReportLookupDataSource.findById(id);
    if (report == null) return;

    final patient = await PatientLookupDataSource.findById(report.patientId);
    final encounterId = report.clinicalEncounterId?.trim() ?? '';
    final encounter = encounterId.isEmpty
        ? null
        : await ClinicalEncounterLookupDataSource.findById(encounterId);

    final result = await ClinicalReportPdfGenerator.instance.generate(
      report: report,
      patientIdentityNumber:
          ClinicalReportPdfPatientIdentity.turkishNationalIdForPdf(patient),
      clinicalEncounterProtocolNumber: encounter?.hasProtocolNumber == true
          ? encounter!.displayProtocolNumber
          : null,
      encounterDate: encounter?.createdAt,
    );

    await Printing.layoutPdf(
      name: result.fileName,
      onLayout: (_) async => result.bytes,
    );
  }

  static Future<void> _printPrescription(String id) async {
    final prescription = await PrescriptionLookupDataSource.findById(id);
    if (prescription == null) return;

    final patient = await PatientLookupDataSource.findById(prescription.patientId);
    final encounterId = prescription.clinicalEncounterId?.trim() ?? '';
    final encounter = encounterId.isEmpty
        ? null
        : await ClinicalEncounterLookupDataSource.findById(encounterId);

    final result = await PrescriptionPdfGenerator.instance.generate(
      prescription: prescription,
      patientFileNumber: patient?.fileNumber ?? '',
      clinicalEncounterProtocolNumber: encounter?.hasProtocolNumber == true
          ? encounter!.displayProtocolNumber
          : null,
    );

    await Printing.layoutPdf(
      name: result.fileName,
      onLayout: (_) async => result.bytes,
    );
  }

  static Future<void> _printLabOrder(String id) async {
    final order = await LabOrderLookupDataSource.findById(id);
    if (order == null) return;

    final patient = await PatientLookupDataSource.findById(order.patientId);
    final encounterId = order.clinicalEncounterId?.trim() ?? '';
    final encounter = encounterId.isEmpty
        ? null
        : await ClinicalEncounterLookupDataSource.findById(encounterId);

    final result = await LabOrderPdfGenerator.instance.generate(
      order: order,
      patientIdentityNumber:
          ClinicalPdfPatientIdentity.turkishNationalIdForPdf(patient),
      patientFileNumber: patient?.fileNumber ?? '',
      clinicalEncounterProtocolNumber:
          _resolveLabProtocolNumber(order, encounter),
    );

    await Printing.layoutPdf(
      name: result.fileName,
      onLayout: (_) async => result.bytes,
    );
  }

  static Future<void> _printRadiologyOrder(String id) async {
    final order = await RadiologyOrderLookupDataSource.findById(id);
    if (order == null) return;

    final patient = await PatientLookupDataSource.findById(order.patientId);
    final encounterId = order.clinicalEncounterId?.trim() ?? '';
    final encounter = encounterId.isEmpty
        ? null
        : await ClinicalEncounterLookupDataSource.findById(encounterId);

    final result = await RadiologyOrderPdfGenerator.instance.generate(
      order: order,
      patientIdentityNumber:
          ClinicalPdfPatientIdentity.turkishNationalIdForPdf(patient),
      patientFileNumber: patient?.fileNumber ?? '',
      clinicalEncounterProtocolNumber: encounter?.hasProtocolNumber == true
          ? encounter!.displayProtocolNumber
          : null,
    );

    await Printing.layoutPdf(
      name: result.fileName,
      onLayout: (_) async => result.bytes,
    );
  }

  static String? _resolveLabProtocolNumber(
    LabOrder order,
    ClinicalEncounter? encounter,
  ) {
    final snapshot = order.displayProtocolNumber;
    if (snapshot != null) return snapshot;
    if (encounter?.hasProtocolNumber == true) {
      return encounter!.displayProtocolNumber;
    }
    return null;
  }
}

Future<bool> showPostEncounterPrintPrompt(
  BuildContext context, {
  required PostEncounterDocumentKind kind,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Yazıcıya gönder?'),
      content: Text('${kind.label} kaydedildi. PDF yazdırmak ister misiniz?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hayır'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Evet'),
        ),
      ],
    ),
  );
  return result ?? false;
}
