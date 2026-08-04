import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../../ai/application/generate_application_messages_usecase.dart';
import '../../ai/domain/entities/application_messages.dart';
import '../domain/clipboard_copier.dart';

/// Les quatre canaux de message generes. Enum localise-agnostique : la
/// presentation mappe vers les libelles traduits (issue #245, G5).
enum MessageKind { coverLetter, email, linkedIn, whatsApp }

/// Etat et orchestration de la generation de messages de candidature
/// (issue #245, G5).
///
/// Porte le ton choisi, le chargement, l'erreur TYPEE et le resultat typé
/// [ApplicationMessages]. La generation passe par
/// [GenerateApplicationMessagesUseCase] (port `AiRepository`) — plus de
/// `Map<String, dynamic>` ni d'anti-pattern `error.toString()`. La copie est
/// DELEGUEE a [ClipboardCopier], separee de la generation.
class ApplicationMessagesController extends ChangeNotifier {
  ApplicationMessagesController({
    required int cvId,
    required String jobDescription,
    required GenerateApplicationMessagesUseCase generate,
    required ClipboardCopier clipboard,
    this.onAiError,
    String initialTone = defaultTone,
  })  : _cvId = cvId,
        _jobDescription = jobDescription,
        _generate = generate,
        _clipboard = clipboard,
        _tone = initialTone;

  /// Ton par defaut (reproduit le monolithe).
  static const String defaultTone = 'PROFESSIONAL';

  /// Tons proposes, dans l'ordre d'affichage. Les libelles sont resolus cote
  /// presentation (domaine localise-agnostique).
  static const List<String> tones = [
    'SIMPLE',
    'PROFESSIONAL',
    'DIRECT',
    'JUNIOR',
    'SENIOR',
  ];

  final int _cvId;
  final String _jobDescription;
  final GenerateApplicationMessagesUseCase _generate;
  final ClipboardCopier _clipboard;

  /// Notifie la vue d'une erreur IA typee (ex. pour AiStatusProvider).
  final void Function(AiException error)? onAiError;

  String _tone;
  bool _loading = false;
  AppException? _error;
  ApplicationMessages? _messages;

  String get tone => _tone;
  bool get loading => _loading;
  AppException? get error => _error;
  ApplicationMessages? get messages => _messages;

  /// Change le ton et invalide le resultat courant (il ne correspond plus au
  /// ton). Sans effet pendant un chargement.
  void selectTone(String value) {
    if (_loading || value == _tone) return;
    _tone = value;
    _messages = null;
    notifyListeners();
  }

  /// Genere les messages via le use case. Rejouable (retry) : efface l'erreur
  /// precedente.
  Future<void> generate() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    final outcome = await _generate(GenerateApplicationMessagesParams(
      cvId: _cvId,
      jobDescription: _jobDescription,
      tone: _tone,
    ));

    switch (outcome) {
      case Success(:final data):
        _messages = data;
      case Failure(:final exception):
        _error = exception;
        if (exception is AiException) onAiError?.call(exception);
    }
    _loading = false;
    notifyListeners();
  }

  /// Copie le message [kind] vers le presse-papier via [ClipboardCopier].
  /// Retourne `true` si un texte non vide a ete copie (la vue affiche alors la
  /// confirmation), `false` sinon.
  Future<bool> copy(MessageKind kind) async {
    final text = textOf(kind);
    if (text.isEmpty) return false;
    await _clipboard.copy(text);
    return true;
  }

  /// Texte associe a un canal, ou chaine vide si absent.
  String textOf(MessageKind kind) {
    final m = _messages;
    if (m == null) return '';
    return switch (kind) {
      MessageKind.coverLetter => m.coverLetter ?? '',
      MessageKind.email => m.email ?? '',
      MessageKind.linkedIn => m.linkedIn ?? '',
      MessageKind.whatsApp => m.whatsApp ?? '',
    };
  }
}
