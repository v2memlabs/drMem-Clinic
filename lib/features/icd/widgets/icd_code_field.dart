import 'dart:async';

import 'package:flutter/material.dart';

import '../models/icd_code.dart';
import '../services/icd_lookup_service.dart';

/// ICD kodu alanı: yerel autocomplete + manuel kod girişi.
class IcdCodeField extends StatefulWidget {
  const IcdCodeField({
    super.key,
    required this.initialCode,
    this.initialTitle,
    this.labelText = 'ICD Kodu',
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final String initialCode;
  final String? initialTitle;
  final String labelText;
  final void Function(String code, IcdCode? selectedCode) onChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  State<IcdCodeField> createState() => _IcdCodeFieldState();
}

class _IcdCodeFieldState extends State<IcdCodeField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  List<IcdCode> _suggestions = [];
  bool _loading = false;
  Timer? _debounce;
  String? _selectedTitle;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialCode);
    _selectedTitle = widget.initialTitle;
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch(_controller.text));
  }

  @override
  void didUpdateWidget(IcdCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCode != widget.initialCode && _controller.text != widget.initialCode) {
      _controller.text = widget.initialCode;
      _selectedTitle = widget.initialTitle;
      _runSearch(widget.initialCode);
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _runSearch(_controller.text);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      _runSearch(value);
      widget.onChanged(value.trim(), null);
      setState(() => _selectedTitle = null);
    });
  }

  Future<void> _runSearch(String query) async {
    setState(() => _loading = true);
    final results = await IcdLookupService.instance.search(query);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _loading = false;
    });
  }

  void _select(IcdCode item) {
    _controller.text = item.code;
    _selectedTitle = item.titleTr;
    _suggestions = [];
    widget.onChanged(item.code, item);
    setState(() {});
    _focusNode.unfocus();
  }

  bool get _showManualHint {
    final text = _controller.text.trim();
    if (text.isEmpty) return false;
    return !_suggestions.any((s) => normalizeIcdSearchText(s.code) == normalizeIcdSearchText(text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          decoration: InputDecoration(
            labelText: widget.labelText,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search, size: 20),
            helperText: 'Kod veya tanı adıyla arayın; listede yoksa manuel kod girebilirsiniz.',
          ),
          validator: widget.validator == null ? null : (v) => widget.validator!(v),
          onChanged: _onTextChanged,
        ),
        if (_selectedTitle != null && _selectedTitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              formatIcdDisplay(_controller.text, _selectedTitle),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
        if (_focusNode.hasFocus && _suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.surface,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                      maxHeight: 220,
                    ),
                    child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _suggestions[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        item.code,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        item.titleTr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: item.category != null && item.category!.isNotEmpty
                          ? Chip(
                              label: Text(item.category!, style: theme.textTheme.labelSmall),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )
                          : null,
                      onTap: () => _select(item),
                    );
                  },
                ),
                  ),
                );
              },
            ),
          ),
        if (_focusNode.hasFocus && _showManualHint)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '«${_controller.text.trim()}» manuel ICD kodu olarak kullanılacak',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
