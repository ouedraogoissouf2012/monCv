import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/job_application.dart';
import '../../providers/cv_provider.dart';
import '../../providers/job_application_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/app_scaffold.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobApplicationProvider>().load();
      context.read<CvProvider>().loadCvs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDesktop = Responsive.isDesktop(context);
    return AppScaffold(
      currentIndex: 2,
      title: l.applications,
      actions: isDesktop
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FilledButton.icon(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l.addApplication),
                ),
              ),
            ]
          : null,
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              tooltip: l.addApplication,
              onPressed: () => _openForm(context),
              child: const Icon(Icons.add),
            ),
      body: Consumer<JobApplicationProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => provider.load(status: provider.filter),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        isDesktop ? 24 : 16, 20, isDesktop ? 24 : 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (provider.dueItems.isNotEmpty)
                          _FollowUpBanner(count: provider.dueItems.length),
                        const SizedBox(height: 12),
                        _StatusFilters(
                          selected: provider.filter,
                          onSelected: (status) => provider.load(status: status),
                        ),
                        if (provider.error != null) ...[
                          const SizedBox(height: 12),
                          Text(provider.error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        ],
                      ],
                    ),
                  ),
                ),
                if (provider.items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyApplications(onAdd: () => _openForm(context)),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        isDesktop ? 24 : 16, 8, isDesktop ? 24 : 16, 96),
                    sliver: SliverList.separated(
                      itemCount: provider.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _ApplicationRow(
                        value: provider.items[index],
                        onEdit: () => _openForm(context, provider.items[index]),
                        onDelete: () => _delete(context, provider.items[index]),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, [JobApplication? value]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ApplicationFormSheet(value: value),
    );
  }

  Future<void> _delete(BuildContext context, JobApplication value) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteApplication),
        content: Text(l.deleteApplicationConfirm(value.company)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l.delete)),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<JobApplicationProvider>().delete(value.id!);
    }
  }
}

class _StatusFilters extends StatelessWidget {
  final JobApplicationStatus? selected;
  final ValueChanged<JobApplicationStatus?> onSelected;
  const _StatusFilters({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final values = <JobApplicationStatus?>[null, ...JobApplicationStatus.values];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = values[index];
          return ChoiceChip(
            label: Text(value == null ? l.all : _statusLabel(l, value)),
            selected: selected == value,
            onSelected: (_) => onSelected(value),
          );
        },
      ),
    );
  }
}

class _ApplicationRow extends StatelessWidget {
  final JobApplication value;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ApplicationRow({
    required this.value,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _statusColor(value.status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.business_center_outlined,
                  color: _statusColor(value.status), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(value.position,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )),
                      ),
                      _StatusBadge(value.status),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(value.company,
                      style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.7))),
                  if (value.cvTitle != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.description_outlined, size: 15),
                      const SizedBox(width: 5),
                      Flexible(
                          child: Text(
                              '${value.cvVariant ? '${l.variant} · ' : ''}${value.cvTitle}',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall)),
                    ]),
                  ],
                  if (value.nextFollowUp != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(value.followUpDue ? Icons.notification_important : Icons.schedule,
                          size: 16,
                          color: value.followUpDue
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant),
                      const SizedBox(width: 5),
                      Text(
                        '${l.nextFollowUp}: ${dateFormat.format(value.nextFollowUp!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: value.followUpDue ? colorScheme.error : null,
                              fontWeight: value.followUpDue ? FontWeight.w600 : null,
                            ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'edit') onEdit();
                if (action == 'delete') onDelete();
                if (action == 'open' && value.offerUrl != null) {
                  final uri = Uri.tryParse(value.offerUrl!);
                  if (uri != null) await launchUrl(uri);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l.edit)),
                if (value.offerUrl != null)
                  PopupMenuItem(value: 'open', child: Text(l.openOffer)),
                PopupMenuItem(value: 'delete', child: Text(l.delete)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final JobApplicationStatus status;
  const _StatusBadge(this.status);
  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(_statusLabel(AppLocalizations.of(context)!, status),
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _FollowUpBanner extends StatelessWidget {
  final int count;
  const _FollowUpBanner({required this.count});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        const Icon(Icons.notifications_active_outlined, color: Color(0xFFB45309)),
        const SizedBox(width: 10),
        Expanded(child: Text(l.followUpsDue(count), style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _EmptyApplications extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyApplications({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.work_outline, size: 52, color: Color(0xFF94A3B8)),
          const SizedBox(height: 14),
          Text(l.noApplications, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(l.noApplicationsDescription, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(l.addApplication)),
        ]),
      ),
    );
  }
}

class _ApplicationFormSheet extends StatefulWidget {
  final JobApplication? value;
  const _ApplicationFormSheet({this.value});
  @override
  State<_ApplicationFormSheet> createState() => _ApplicationFormSheetState();
}

class _ApplicationFormSheetState extends State<_ApplicationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _company;
  late final TextEditingController _position;
  late final TextEditingController _url;
  late final TextEditingController _notes;
  late JobApplicationStatus _status;
  int? _cvId;
  DateTime? _sentDate;
  DateTime? _followUp;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final value = widget.value;
    _company = TextEditingController(text: value?.company);
    _position = TextEditingController(text: value?.position);
    _url = TextEditingController(text: value?.offerUrl);
    _notes = TextEditingController(text: value?.notes);
    _status = value?.status ?? JobApplicationStatus.draft;
    _cvId = value?.cvId;
    _sentDate = value?.sentDate;
    _followUp = value?.nextFollowUp;
  }

  @override
  void dispose() {
    _company.dispose();
    _position.dispose();
    _url.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cvs = context.watch<CvProvider>().cvs;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(widget.value == null ? l.addApplication : l.editApplication,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), tooltip: l.close),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _company,
              decoration: InputDecoration(labelText: l.company, prefixIcon: const Icon(Icons.business_outlined)),
              validator: (value) => value == null || value.trim().isEmpty ? l.requiredField : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _position,
              decoration: InputDecoration(labelText: l.position, prefixIcon: const Icon(Icons.badge_outlined)),
              validator: (value) => value == null || value.trim().isEmpty ? l.requiredField : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<JobApplicationStatus>(
              initialValue: _status,
              decoration: InputDecoration(labelText: l.status, prefixIcon: const Icon(Icons.flag_outlined)),
              items: JobApplicationStatus.values
                  .map((status) => DropdownMenuItem(value: status, child: Text(_statusLabel(l, status))))
                  .toList(),
              onChanged: (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _cvId ?? -1,
              decoration: InputDecoration(labelText: l.linkedCv, prefixIcon: const Icon(Icons.description_outlined)),
              items: [
                DropdownMenuItem<int>(value: -1, child: Text(l.noLinkedCv)),
                ...cvs.where((cv) => cv.id != null).map((cv) => DropdownMenuItem<int>(
                      value: cv.id,
                      child: Text(cv.isVariante ? '${cv.titre} · ${l.variant}' : cv.titre,
                          overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (value) => setState(() => _cvId = value == -1 ? null : value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l.offerLink, prefixIcon: const Icon(Icons.link)),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _DateField(label: l.sentDate, value: _sentDate,
                  onChanged: (date) => setState(() => _sentDate = date))),
              const SizedBox(width: 10),
              Expanded(child: _DateField(label: l.nextFollowUp, value: _followUp,
                  onChanged: (date) => setState(() => _followUp = date))),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(labelText: l.notes, alignLabelWithHint: true),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: Text(l.save),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final success = await context.read<JobApplicationProvider>().save(JobApplication(
          id: widget.value?.id,
          cvId: _cvId,
          company: _company.text.trim(),
          position: _position.text.trim(),
          offerUrl: _url.text.trim().isEmpty ? null : _url.text.trim(),
          status: _status,
          sentDate: _sentDate,
          nextFollowUp: _followUp,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ));
    if (success && mounted) Navigator.pop(context);
    if (mounted) setState(() => _saving = false);
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  const _DateField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return OutlinedButton.icon(
      onPressed: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (selected != null) onChanged(selected);
      },
      icon: const Icon(Icons.calendar_today_outlined, size: 17),
      label: Text(value == null ? label : DateFormat.yMd(locale).format(value!),
          overflow: TextOverflow.ellipsis),
    );
  }
}

String _statusLabel(AppLocalizations l, JobApplicationStatus status) => switch (status) {
      JobApplicationStatus.draft => l.applicationDraft,
      JobApplicationStatus.sent => l.applicationSent,
      JobApplicationStatus.interview => l.applicationInterview,
      JobApplicationStatus.technicalTest => l.applicationTechnicalTest,
      JobApplicationStatus.offer => l.applicationOffer,
      JobApplicationStatus.rejected => l.applicationRejected,
      JobApplicationStatus.archived => l.applicationArchived,
    };

Color _statusColor(JobApplicationStatus status) => switch (status) {
      JobApplicationStatus.draft => const Color(0xFF64748B),
      JobApplicationStatus.sent => const Color(0xFF2563EB),
      JobApplicationStatus.interview => const Color(0xFF7C3AED),
      JobApplicationStatus.technicalTest => const Color(0xFFD97706),
      JobApplicationStatus.offer => const Color(0xFF059669),
      JobApplicationStatus.rejected => const Color(0xFFDC2626),
      JobApplicationStatus.archived => const Color(0xFF475569),
    };
