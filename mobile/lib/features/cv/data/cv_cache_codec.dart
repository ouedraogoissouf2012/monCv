import '../presentation/cv_presentation_model.dart';
import 'mappers/cv_mapper.dart';

/// Codec de cache/file offline du CV : (de)serialise un CV isole via le schema
/// versionne de [CvMapper], en manipulant le modele de presentation [Cv].
const CvMapper _mapper = CvMapper();

/// Encode un CV pour la file de synchronisation offline (schema versionne).
String cvToQueueString(Cv cv) => _mapper.cvToCacheString(cv.entity);

/// Decode un CV de la file offline, ou `null` si absent/corrompu.
Cv? cvFromQueueString(String? json) {
  final entity = json == null ? null : _mapper.cvFromCacheString(json);
  return entity == null ? null : Cv.fromEntity(entity);
}
