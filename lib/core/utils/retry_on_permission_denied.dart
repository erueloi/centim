import 'package:cloud_firestore/cloud_firestore.dart';

/// Escolta el stream que retorna [open] i, si falla amb `permission-denied`,
/// el torna a obrir després de cada espera de [delays].
///
/// Just després d'iniciar sessió o registrar-se, Firestore pot rebre la
/// primera escolta abans de tenir el token del nou usuari (passa sobretot al
/// web) i les regles la deneguen tot i ser legítima. Uns pocs reintents curts
/// ho resolen; si continua fallant, l'error es propaga.
Stream<T> retryOnPermissionDenied<T>(
  Stream<T> Function() open, {
  List<Duration> delays = const [
    Duration(milliseconds: 300),
    Duration(milliseconds: 800),
    Duration(milliseconds: 1500),
  ],
}) async* {
  for (var attempt = 0;; attempt++) {
    try {
      await for (final value in open()) {
        yield value;
      }
      return;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied' || attempt >= delays.length) rethrow;
      await Future<void>.delayed(delays[attempt]);
    }
  }
}
