import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/strict_date_input.dart';

class StrictDateField extends StatefulWidget {
  const StrictDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onChanged,
    this.minYear,
    this.maxYear,
    this.notBefore,
    this.notAfter,
    this.required = false,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;
  final int? minYear;
  final int? maxYear;
  final DateTime? notBefore;
  final DateTime? notAfter;
  final bool required;

  @override
  State<StrictDateField> createState() => _StrictDateFieldState();
}

class _StrictDateFieldState extends State<StrictDateField> {
  late final TextEditingController _controller;
  String? _error;

  int get _minYear => widget.minYear ?? StrictDateInput.minYearDefault;
  int get _maxYear => widget.maxYear ?? StrictDateInput.maxCareerYear();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.date == null ? '' : StrictDateInput.format(widget.date!),
    );
  }

  @override
  void didUpdateWidget(covariant StrictDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date != oldWidget.date) {
      final next =
          widget.date == null ? '' : StrictDateInput.format(widget.date!);
      if (_controller.text != next) _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final reason = StrictDateInput.rejectReason(
      digits,
      minYear: _minYear,
      maxYear: _maxYear,
    );
    if (reason != null) {
      final kept = digits.substring(0, digits.length - 1);
      _controller.value = TextEditingValue(
        text: StrictDateInput.mask(kept),
        selection:
            TextSelection.collapsed(offset: StrictDateInput.mask(kept).length),
      );
      setState(() => _error = reason);
      widget.onChanged(StrictDateInput.parse(_controller.text));
      return;
    }
    final masked = StrictDateInput.mask(digits);
    if (masked != raw) {
      _controller.value = TextEditingValue(
        text: masked,
        selection: TextSelection.collapsed(offset: masked.length),
      );
    }
    setState(() => _error = null);
    widget.onChanged(StrictDateInput.parse(masked));
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9/]'))],
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'jj/mm/aaaa',
        errorText: _error,
        prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
      ),
      onChanged: _onChanged,
      validator: (value) {
        if ((value == null || value.trim().isEmpty) && widget.required) {
          return 'Date requise (jj/mm/aaaa).';
        }
        final parsed = value == null ? null : StrictDateInput.parse(value);
        if (value != null && value.isNotEmpty && parsed == null) {
          return 'Format jj/mm/aaaa.';
        }
        if (parsed != null &&
            widget.notBefore != null &&
            parsed.isBefore(widget.notBefore!)) {
          return 'La date de fin doit etre posterieure a la date de debut.';
        }
        if (parsed != null &&
            widget.notAfter != null &&
            parsed.isAfter(widget.notAfter!)) {
          return 'La date de debut doit etre anterieure a la date de fin.';
        }
        return _error;
      },
    );
  }
}
