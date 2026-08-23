import '../../../core/error/result.dart';
import 'cv_presentation_model.dart';

/// Port d'ecriture d'un CV : persiste l'operation PUIS reconcilie l'etat
/// partage ([CvStore]) — issue #501.
///
/// Toute ecriture de CV declenchee par l'UI (formulaire, feuille d'analyse
/// d'offre) passe par ce port, jamais par un `CvRepository` ni un use case
/// directement. C'est cet invariant qui garantit qu'apres une sauvegarde la
/// liste ET le CV courant refletent la version persistee, sans rechargement.
///
/// Historique du bug : un ecran qui appelait `CvRepository.updateCv` en direct
/// laissait `CvStore.currentCv` sur la copie chargee a l'ouverture ; l'ecran de
/// detail affichait donc l'ancien contenu apres une edition reussie, et une
/// variante creee n'apparaissait pas dans la liste. Un premier correctif avait
/// place la reconciliation dans le widget, via un service locator : le symptome
/// disparaissait mais la regle restait facultative, donc reintroductible.
///
/// Le [Result] est retourne a l'appelant plutot que reduit a un booleen : le
/// formulaire a besoin du message d'erreur pour son affichage inline, sans
/// avoir a lire l'etat du store.
///
/// Implementation de production : `CvEditorController`. Les tests substituent
/// un double conforme a ce contrat, sans construire les use cases ni le store.
abstract interface class CvWriter {
  /// Cree un CV, l'ajoute a l'etat partage et le rend courant.
  Future<Result<Cv>> create(Cv cv);

  /// Met a jour le CV [id] et remplace toutes ses copies dans l'etat partage
  /// (liste + CV courant).
  Future<Result<Cv>> update(int id, Cv cv);

  /// Cree une variante de [cvId] adaptee a [jobDescription] et l'ajoute a
  /// l'etat partage, faute de quoi elle resterait invisible dans la liste.
  Future<Result<Cv>> createVariant(
    int cvId,
    String jobDescription, {
    String? label,
  });
}
