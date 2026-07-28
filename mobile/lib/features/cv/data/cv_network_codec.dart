import 'dart:convert';

import '../presentation/cv_presentation_model.dart';
import 'mappers/cv_mapper.dart';

export '../presentation/cv_presentation_model.dart' show Cv;

/// Codec reseau du CV : convertit entre le JSON du contrat backend et le
/// modele de presentation [Cv], en s'appuyant sur [CvMapper].
///
/// Regroupe le boundary de (de)serialisation hors des services de transport
/// pour eviter d'y disperser la connaissance du format.
const CvMapper _mapper = CvMapper();

/// Decode une reponse CV du serveur.
Cv cvFromNetworkJson(Map<String, dynamic> json) =>
    Cv.fromEntity(_mapper.fromNetworkJson(json));

/// Encode un CV au format minimal attendu par le serveur (creation / update).
String cvToNetworkBody(Cv cv) => jsonEncode(_mapper.toNetworkJson(cv.entity));
