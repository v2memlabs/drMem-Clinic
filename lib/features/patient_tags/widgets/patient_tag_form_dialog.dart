import 'package:flutter/material.dart';

import '../data/patient_tag_repository_contract.dart';
import '../data/patient_tag_repository_provider.dart';
import '../models/patient_tag.dart';

class PatientTagFormDialog extends StatefulWidget {
  const PatientTagFormDialog({super.key});

  @override
  State<PatientTagFormDialog> createState() => _PatientTagFormDialogState();
}

class _PatientTagFormDialogState extends State<PatientTagFormDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  PatientTagColor _color = PatientTagColor.blue;
  String? _nameError;
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<bool> _validate() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Etiket adı zorunludur.');
      return false;
    }
    if (name.length > 32) {
      setState(() => _nameError = 'Etiket adı en fazla 32 karakter olabilir.');
      return false;
    }
    if (await PatientTagRepositoryProvider.repository.existsByName(name)) {
      setState(() => _nameError = 'Bu isimde aktif bir etiket zaten var.');
      return false;
    }
    setState(() => _nameError = null);
    return true;
  }

  Future<void> _save() async {
    if (_busy) return;
    if (!await _validate()) return;

    setState(() => _busy = true);
    try {
      final tag = await PatientTagRepositoryProvider.repository.create(
        name: _nameCtrl.text.trim(),
        color: _color,
        description: _descCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(tag);
    } on PatientTagRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _nameError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _nameError = 'Etiket oluşturulamadı.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Etiket'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameCtrl,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: 'Etiket adı',
                  errorText: _nameError,
                  counterText: '${_nameCtrl.text.length}/32',
                ),
                maxLength: 32,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (opsiyonel)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text('Renk', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PatientTagColor.values.map((c) {
                  final selected = _color == c;
                  return ChoiceChip(
                    label: Text(patientTagColorLabel(c)),
                    selected: selected,
                    onSelected: _busy ? null : (_) => setState(() => _color = c),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                )
              : const Text('Oluştur'),
        ),
      ],
    );
  }
}
