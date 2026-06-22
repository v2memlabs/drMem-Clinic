import 'package:pdf/widgets.dart' as pw;



import '../../pdf_outputs/services/templates/clinical_document_pdf_helpers.dart';

import '../models/prescription.dart';



const List<String> _turkishCardinals = [

  '',

  'bir',

  'iki',

  'üç',

  'dört',

  'beş',

  'altı',

  'yedi',

  'sekiz',

  'dokuz',

  'on',

];



String prescriptionMedicationRomanIndex(int index) {

  const romans = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];

  if (index >= 1 && index <= romans.length) return romans[index - 1];

  return '$index.';

}



String _boxCountWord(int n) {

  if (n >= 1 && n < _turkishCardinals.length) return _turkishCardinals[n];

  return '$n';

}



String _romanNumeral(int n) {

  if (n >= 1 && n <= 10) return prescriptionMedicationRomanIndex(n);

  return '$n';

}



int? _parseBoxCount(PrescriptionMedication med) {

  if (med.boxCount != null && med.boxCount! > 0) return med.boxCount;

  final dose = med.dose.trim();

  final parsed = int.tryParse(dose);

  if (parsed != null && parsed > 0) return parsed;

  return null;

}



String _normalizeFrequency(String frequency) {

  final trimmed = frequency.trim();

  if (trimmed.isEmpty) return '';



  final nxPattern = RegExp(r'(\d+)\s*[xX×]\s*(\d+)');

  final nx = nxPattern.firstMatch(trimmed);

  if (nx != null) {

    return '${nx.group(1)} x ${nx.group(2)}';

  }



  final gundePattern = RegExp(r'günde\s*(\d+)', caseSensitive: false);

  final gunde = gundePattern.firstMatch(trimmed);

  if (gunde != null) {

    return '${gunde.group(1)} x 1';

  }



  return trimmed;

}



String _normalizeDuration(String duration) {

  final trimmed = duration.trim();

  if (trimmed.isEmpty) return '';

  if (trimmed.toLowerCase().contains('gün')) return trimmed;

  if (RegExp(r'^\d+$').hasMatch(trimmed)) return '$trimmed gün';

  return trimmed;

}



String _usageLine(PrescriptionMedication med) {

  final freq = _normalizeFrequency(med.frequency);

  final duration = _normalizeDuration(med.duration);

  final note = med.notes?.trim() ?? '';



  String line;

  if (freq.isNotEmpty && duration.isNotEmpty) {

    line = '$freq  /  $duration';

  } else if (freq.isNotEmpty) {

    line = freq;

  } else if (duration.isNotEmpty) {

    line = duration;

  } else {

    line = '';

  }



  if (line.isEmpty && note.isEmpty) return 'Belirtilmedi';

  if (note.isNotEmpty) {

    line = line.isEmpty ? '[Not: $note]' : '$line [Not: $note]';

  }

  return line;

}



List<pw.Widget> buildPrescriptionMedicationSection(

  List<PrescriptionMedication> medications,

  pw.Font baseFont,

  pw.Font boldFont,

) {

  if (medications.isEmpty) {

    return [

      pw.Text(

        'İlaç kaydı bulunmuyor.',

        style: pw.TextStyle(font: baseFont, fontSize: 10),

      ),

    ];

  }



  return [

    clinicalDocSectionTitle('İlaçlar', boldFont),

    pw.SizedBox(height: 6),

    clinicalDocEdgeToEdgeFrame(

      children: [

        pw.Text('Rp/', style: pw.TextStyle(font: boldFont, fontSize: 10)),

        pw.SizedBox(height: 6),

        ...medications.asMap().entries.expand((entry) {

          final index = entry.key + 1;

          final med = entry.value;

          final roman = prescriptionMedicationRomanIndex(index);

          final boxCount = _parseBoxCount(med);

          final children = <pw.Widget>[

            pw.Text(

              '$roman. ${med.name.trim()}',

              style: pw.TextStyle(font: boldFont, fontSize: 10),

            ),

          ];



          if (boxCount != null) {

            final boxRoman = _romanNumeral(boxCount);

            children.add(

              pw.Padding(

                padding: const pw.EdgeInsets.only(left: 12, top: 2),

                child: pw.Text(

                  'D $boxRoman B (${_boxCountWord(boxCount)})',

                  style: pw.TextStyle(font: baseFont, fontSize: 10),

                ),

              ),

            );

          } else if (med.dose.trim().isNotEmpty) {

            children.add(

              pw.Padding(

                padding: const pw.EdgeInsets.only(left: 12, top: 2),

                child: pw.Text(

                  med.dose.trim(),

                  style: pw.TextStyle(font: baseFont, fontSize: 10),

                ),

              ),

            );

          }



          children.add(

            pw.Padding(

              padding: const pw.EdgeInsets.only(left: 12, top: 2),

              child: pw.Text(

                'S: ${_usageLine(med)}',

                style: pw.TextStyle(font: baseFont, fontSize: 10),

              ),

            ),

          );



          if (index < medications.length) {

            children.add(pw.SizedBox(height: 8));

          }



          return children;

        }),

      ],

    ),

  ];

}


