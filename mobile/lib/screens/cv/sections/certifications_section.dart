import 'package:flutter/material.dart';

import '../../../features/cv/presentation/section_editor/editable_section_list.dart';
import '../../../features/cv/presentation/section_editor/section_editor_sheet.dart';
import '../../../features/cv/presentation/section_editor/section_primitives.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/cv.dart';
import '../../../features/cv/presentation/section_editor/section_form_fields.dart'
    show SectionDateButton;

class CertificationsSection extends StatelessWidget {
  final List<Certification> certifications;
  final Function(List<Certification>) onChanged;

  const CertificationsSection({
    super.key,
    required this.certifications,
    required this.onChanged,
  });

  /// Ouvre l'editeur de certification et retourne la valeur saisie (ou `null`
  /// si annule / invalide). Ne mute jamais la liste parent : c'est
  /// [EditableSectionList] qui applique le resultat.
  Future<Certification?> _editSheet(
    BuildContext context,
    Certification? cert,
  ) {
    final l = AppLocalizations.of(context)!;
    final nomCtrl = TextEditingController(text: cert?.nom);
    final organismeCtrl = TextEditingController(text: cert?.organisme);
    final urlCtrl = TextEditingController(text: cert?.credentialUrl);
    DateTime? dateObtention = cert?.dateObtention;
    DateTime? dateExpiration = cert?.dateExpiration;

    return showSectionEditor<Certification>(
      context: context,
      title: cert == null ? l.addCertification : l.editCertification,
      icon: Icons.verified_outlined,
      content: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nomCtrl,
            decoration: InputDecoration(
              labelText: l.certificationNameRequired,
              prefixIcon: const Icon(Icons.verified_outlined, size: 20),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l.fieldRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: organismeCtrl,
            decoration: InputDecoration(
              labelText: l.issuingOrganization,
              prefixIcon: const Icon(Icons.business_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SectionDateButton(
                  label: l.issueDate,
                  date: dateObtention,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: dateObtention ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => dateObtention = d);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SectionDateButton(
                  label: l.expiration,
                  date: dateExpiration,
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: dateExpiration ?? DateTime.now(),
                      firstDate: DateTime(1990),
                      lastDate: DateTime(2040),
                    );
                    if (d != null) setState(() => dateExpiration = d);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: urlCtrl,
            decoration: InputDecoration(
              labelText: l.verificationLink,
              prefixIcon: const Icon(Icons.link_rounded, size: 20),
              hintText: 'https://...',
            ),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      buildResult: () => Certification(
        id: cert?.id,
        nom: nomCtrl.text.trim(),
        organisme:
            organismeCtrl.text.isNotEmpty ? organismeCtrl.text : null,
        dateObtention: dateObtention,
        dateExpiration: dateExpiration,
        credentialUrl: urlCtrl.text.isNotEmpty ? urlCtrl.text : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return EditableSectionList<Certification>(
      items: certifications,
      onChanged: onChanged,
      onAdd: (ctx) => _editSheet(ctx, null),
      onEdit: (ctx, current) => _editSheet(ctx, current),
      addLabel: l.addCertification,
      emptyIcon: Icons.verified_outlined,
      emptyLabel: l.noneCertification,
      itemBuilder: (ctx, cert, index,
          {required onEditItem, required onDeleteItem}) {
        final expired = cert.dateExpiration != null &&
            cert.dateExpiration!.isBefore(DateTime.now());
        return SectionItemTile(
          title: cert.nom?.isNotEmpty == true ? cert.nom! : l.certifications,
          subtitle: cert.organisme ?? '',
          badge: expired ? l.expired : null,
          badgeColor: Colors.orange,
          onEdit: onEditItem,
          onDelete: onDeleteItem,
        );
      },
    );
  }
}
