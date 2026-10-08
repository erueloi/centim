import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:centim/core/utils/retry_on_permission_denied.dart';

FirebaseException _error(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

const _noDelays = [Duration.zero, Duration.zero, Duration.zero];

void main() {
  test('si la primera escolta es denega, la torna a obrir i continua', () async {
    var opens = 0;
    final stream = retryOnPermissionDenied<int>(
      () {
        opens++;
        if (opens == 1) return Stream.error(_error('permission-denied'));
        return Stream.fromIterable([1, 2]);
      },
      delays: _noDelays,
    );

    expect(await stream.toList(), [1, 2]);
    expect(opens, 2);
  });

  test('si es continua denegant, propaga l\'error després dels reintents',
      () async {
    var opens = 0;
    final stream = retryOnPermissionDenied<int>(
      () {
        opens++;
        return Stream.error(_error('permission-denied'));
      },
      delays: _noDelays,
    );

    await expectLater(
      stream,
      emitsError(isA<FirebaseException>()
          .having((e) => e.code, 'code', 'permission-denied')),
    );
    expect(opens, 4); // 1 intent + 3 reintents
  });

  test('altres errors no es reintenten', () async {
    var opens = 0;
    final stream = retryOnPermissionDenied<int>(
      () {
        opens++;
        return Stream.error(_error('unavailable'));
      },
      delays: _noDelays,
    );

    await expectLater(stream, emitsError(isA<FirebaseException>()));
    expect(opens, 1);
  });

  test('els valors anteriors a un error es conserven en reobrir', () async {
    var opens = 0;
    final stream = retryOnPermissionDenied<String>(
      () {
        opens++;
        if (opens == 1) {
          final controller = StreamController<String>();
          controller
            ..add('abans')
            ..addError(_error('permission-denied'))
            ..close();
          return controller.stream;
        }
        return Stream.value('després');
      },
      delays: _noDelays,
    );

    expect(await stream.toList(), ['abans', 'després']);
  });
}
