import 'package:flutter/material.dart';
import '../../../models/cv.dart';
import 'form_sheet.dart';

class CertificationsSection extends StatelessWidget {
  final List<Certification> certifications;
  final Function(List<Certification>) onChanged;

  const CertificationsSection({
    super.key,
    required this.certifications,
    required this.onChanged,
  });

  void _add(BuildContext context) =>
      _showSheet(context, null, (c) => onChanged([...certifications, c]));

  void _edit(BuildContext context, int i) =>
      _showSheet(context, certifications[i], (c) {
        final list = List<Certification>.from(certifications);
        list[i] = c;
        onChanged(list);
      });

  void _delete(int i) {
    final list = List<Certification>.from(certifications);
    list.removeAt(i);
    onChanged(list);
  }

  void _showSheet(
    BuildContext context,
    Certification? cert,
    Function(Certification) onSave,
  ) {
    final nomCtrl = TextEditingController(text: cert?.nom);
    final organismeCtrl = TextEditingController(text: cert?.organisme);
    final urlCtrl = TextEditingController(text: cert?.credentialUrl);
    DateTime? dateObtention = cert?.dateObtention;
    DateTime? dateExpiration = cert?.dateExpiration;

    showFormSheet(
      context: context,
      title: cert == null ? 'Ajouter une certification' : 'Modifier la certification',
      icon: Icons.verified_outlined,
      builder: (ctx, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nomCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom de la certification *',
              prefixIcon: Icon(Icons.verified_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: organismeCtrl,
            decoration: const InputDecoration(
              labelText: 'Organisme émetteur',
              prefixIcon: Icon(Icons.business_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SectionDateButton(
                  label: 'Date d\'obtention',
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
                  label: 'Expiration',
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
            decoration: const InputDecoration(
              labelText: 'Lien de vérification',
              prefixIcon: Icon(Icons.link_rounded, size: 20),
              hintText: 'https://...',
            ),
            keyboardType: TextInputType.url,
          ),
        ],
      ),
      onSave: () => onSave(Certification(
        id: cert?.id,
        nom: nomCtrl.text.isNotEmpty ? nomCtrl.text : null,
        organisme: organismeCtrl.text.isNotEmpty ? organismeCtrl.text : null,
        dateObtention: dateObtention,
        dateExpiration: dateExpiration,
        credentialUrl: urlCtrl.text.isNotEmpty ? urlCtrl.text : null,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (certifications.isEmpty)
          const SectionEmptyState(
            icon: Icons.verified_outlined,
            label: 'Aucune certification ajoutée',
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: certifications.length,
            itemBuilder: (ctx, i) {
              final cert = certifications[i];
              final expired = cert.dateExpiration != null &&
                  cert.dateExpiration!.isBefore(DateTime.now());
              return SectionItemTile(
                title: cert.nom?.isNotEmpty == true ? cert.nom! : 'Certification',
                subtitle: cert.organisme ?? '',
                badge: expired ? 'Expiré' : null,
                badgeColor: Colors.orange,
                onEdit: () => _edit(ctx, i),
                onDelete: () => _delete(i),
              );
            },
          ),
        const SizedBox(height: 8),
        SectionAddButton(
          label: 'Ajouter une certification',
          onTap: () => _add(context),
        ),
      ],
    );
  }
}
