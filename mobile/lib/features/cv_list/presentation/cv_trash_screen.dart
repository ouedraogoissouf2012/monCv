import 'package:flutter/material.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/navigation/app_shell.dart';
import '../../../core/error/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../../repositories/cv_trash_repository.dart';
import '../../cv/presentation/cv_presentation_model.dart';

class CvTrashScreen extends StatefulWidget {
  const CvTrashScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CvTrashScreen> createState() => _CvTrashScreenState();
}

class _CvTrashScreenState extends State<CvTrashScreen> {
  List<Cv> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final result = await sl<CvTrashRepository>().list();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = result is Success<List<Cv>> ? result.data : const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final body = _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(l.trashEmpty))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final cv = _items[index];
                    return ListTile(
                      title: Text(cv.titre),
                      trailing: Wrap(children: [
                        TextButton(
                          onPressed: () async {
                            await sl<CvTrashRepository>().restore(cv.id!);
                            await _reload();
                          },
                          child: Text(l.restore),
                        ),
                        TextButton(
                          onPressed: () async {
                            await sl<CvTrashRepository>().purge(cv.id!);
                            await _reload();
                          },
                          child: Text(l.purgeForever),
                        ),
                      ]),
                    );
                  },
                );
    if (widget.embedded) return body;
    return AppShell(
      currentIndex: 4,
      title: l.trashTitle,
      body: body,
    );
  }
}
