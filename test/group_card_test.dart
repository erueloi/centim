import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:centim/domain/models/household_group.dart';
import 'package:centim/domain/models/user_profile.dart';
import 'package:centim/presentation/providers/group_providers.dart';
import 'package:centim/presentation/screens/settings/group_card.dart';

const _group = HouseholdGroup(
  id: 'gA',
  name: 'Llar A',
  memberIds: ['alice', 'bob', 'orfe'],
  ownerId: 'alice',
  inviteCode: 'ABC123',
);

const _profiles = [
  UserProfile(uid: 'alice', email: 'alice@example.com', name: 'Alice'),
  UserProfile(uid: 'bob', email: 'bob@example.com'),
];

Future<void> _pumpCard(WidgetTester tester, {required String asUid}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUidProvider.overrideWithValue(asUid),
        currentGroupProvider.overrideWith((ref) => Stream.value(_group)),
        groupMembersProvider.overrideWith((ref) async => _profiles),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: GroupCard())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra el codi i tots els membres, també els que no tenen perfil',
      (tester) async {
    await _pumpCard(tester, asUid: 'bob');

    expect(find.text('ABC123'), findsOneWidget);
    expect(find.text('3 membres'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('alice@example.com · Propietari'), findsOneWidget);
    expect(find.text('bob@example.com (tu)'), findsOneWidget);
    expect(find.text('Usuari sense perfil'), findsOneWidget);
  });

  testWidgets('l\'owner gestiona els altres membres i el codi, però no pot sortir',
      (tester) async {
    await _pumpCard(tester, asUid: 'alice');

    // Un menú per a cada membre que no és ell mateix (bob i l'orfe).
    expect(find.byTooltip('Opcions del membre'), findsNWidgets(2));
    expect(find.byTooltip('Generar un codi nou'), findsOneWidget);
    expect(find.text('Sortir del grup'), findsNothing);
    expect(find.textContaining('primer fes propietari'), findsOneWidget);

    await tester.tap(find.byTooltip('Opcions del membre').first);
    await tester.pumpAndSettle();
    expect(find.text('Fer-lo propietari'), findsOneWidget);
    expect(find.text('Treure del grup'), findsOneWidget);
  });

  testWidgets('un membre que no és owner només pot sortir del grup',
      (tester) async {
    await _pumpCard(tester, asUid: 'bob');

    expect(find.byTooltip('Opcions del membre'), findsNothing);
    expect(find.byTooltip('Generar un codi nou'), findsNothing);
    expect(find.text('Sortir del grup'), findsOneWidget);

    await tester.tap(find.text('Sortir del grup'));
    await tester.pumpAndSettle();
    expect(find.text('Sortir del grup?'), findsOneWidget);

    // Cancel·lar no fa res (no toca cap repositori).
    await tester.tap(find.text('Cancel·lar'));
    await tester.pumpAndSettle();
    expect(find.text('Sortir del grup?'), findsNothing);
  });
}
