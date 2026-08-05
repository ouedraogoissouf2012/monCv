import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/cv.dart';
import '../../../../providers/cv_provider.dart';
import '../../domain/job_application.dart';
import '../../domain/job_application_status.dart';
import '../components/application_status_presentation.dart';
import 'application_form_model.dart';

/// Feuille de saisie/edition d'une candidature (issue #246, A6b).
///
/// Pilotee par [ApplicationFormModel] (A5) : la validation est PURE et
/// centralisee dans le modele ; ce widget ne fait que la saisie et affiche les
/// erreurs. Retourne la [JobApplication] validee via `Navigator.pop`, ou `null`
/// si annulee — l'appelant (ecran) la persiste via le controller.
class ApplicationFormSheet extends StatefulWidget {
  const ApplicationFormSheet({super.key, this.initial});

  final JobApplication? initial;

  @override
  State<ApplicationFormSheet> createState() => _ApplicationFormSheetState();
}

class _ApplicationFormSheetState extends State<ApplicationFormSheet> {
  late final TextEditingController _company;
  late final TextEditingController _position;
  late final TextEditingController _url;
  late final TextEditingController _notes;
  late ApplicationFormModel _model;
  ApplicationFormValidation _validation = const ApplicationFormValidation({});
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _model = widget.initial == null
        ? const ApplicationFormModel()
        : ApplicationFormModel.fromApplication(widget.initial!);
    _company = TextEditingController(text: _model.company);
    _position = TextEditingController(text: _model.position);
    _url = TextEditingController(text: _model.offerUrl);
    _notes = TextEditingController(text: _model.notes);
  }

  @override
  void dispose() {
    _company.dispose();
    _position.dispose();
    _url.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _errorText(AppLocalizations l, ApplicationFormField field) {
    if (!_submitted) return null;
    return switch (_validation.errorFor(field)) {
      ApplicationFieldError.required => l.requiredField,
      ApplicationFieldError.invalidUrl => l.invalidUrl,
      ApplicationFieldError.followUpBeforeSent => l.followUpBeforeSent,
      null => null,
    };
  }

  void _submit() {
    _model = _model.copyWith(
      company: _company.text,
      position: _position.text,
      offerUrl: _url.text,
      notes: _notes.text,
    );
    final validation = _model.validate();
    setState(() {
      _submitted = true;
      _validation = validation;
    });
    if (validation.isValid) Navigator.pop(context, _model.toApplication());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cvs = context.watch<CvProvider>().cvs;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                    widget.initial == null
                        ? l.addApplication
                        : l.editApplication,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: l.close),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _company,
              decoration: InputDecoration(
                labelText: l.company,
                prefixIcon: const Icon(Icons.business_outlined),
                errorText: _errorText(l, ApplicationFormField.company),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _position,
              decoration: InputDecoration(
                labelText: l.position,
                prefixIcon: const Icon(Icons.badge_outlined),
                errorText: _errorText(l, ApplicationFormField.position),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<JobApplicationStatus>(
              initialValue: _model.status,
              decoration: InputDecoration(
                  labelText: l.status,
                  prefixIcon: const Icon(Icons.flag_outlined)),
              items: JobApplicationStatus.values
                  .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(ApplicationStatusPresentation.label(l, s))))
                  .toList(),
              onChanged: (s) =>
                  setState(() => _model = _model.copyWith(status: s)),
            ),
            const SizedBox(height: 12),
            _CvDropdown(
              cvs: cvs,
              selected: _model.cvId,
              onChanged: (id) => setState(() => _model = id == null
                  ? _model.copyWith(clearCvId: true)
                  : _model.copyWith(cvId: id)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l.offerLink,
                prefixIcon: const Icon(Icons.link),
                errorText: _errorText(l, ApplicationFormField.offerUrl),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: _DateField(
                      label: l.sentDate,
                      value: _model.sentDate,
                      onChanged: (d) => setState(
                          () => _model = _model.copyWith(sentDate: d)))),
              const SizedBox(width: 10),
              Expanded(
                  child: _DateField(
                      label: l.nextFollowUp,
                      value: _model.nextFollowUp,
                      error: _errorText(l, ApplicationFormField.followUp),
                      onChanged: (d) => setState(
                          () => _model = _model.copyWith(nextFollowUp: d)))),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 3,
              maxLines: 5,
              decoration:
                  InputDecoration(labelText: l.notes, alignLabelWithHint: true),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(l.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CvDropdown extends StatelessWidget {
  const _CvDropdown(
      {required this.cvs, required this.selected, required this.onChanged});

  final List<Cv> cvs;
  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DropdownButtonFormField<int>(
      initialValue: selected ?? -1,
      decoration: InputDecoration(
          labelText: l.linkedCv,
          prefixIcon: const Icon(Icons.description_outlined)),
      items: [
        DropdownMenuItem<int>(value: -1, child: Text(l.noLinkedCv)),
        ...cvs.where((cv) => cv.id != null).map((cv) => DropdownMenuItem<int>(
              value: cv.id,
              child: Text(cv.isVariante ? '${cv.titre} · ${l.variant}' : cv.titre,
                  overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (v) => onChanged(v == -1 ? null : v),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.error,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final selected = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (selected != null) onChanged(selected);
          },
          icon: const Icon(Icons.calendar_today_outlined, size: 17),
          label: Text(
              value == null ? label : DateFormat.yMd(locale).format(value!),
              overflow: TextOverflow.ellipsis),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(error!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ),
      ],
    );
  }
}
