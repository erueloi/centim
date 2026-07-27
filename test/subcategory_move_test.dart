import 'package:flutter_test/flutter_test.dart';
import 'package:centim/domain/models/category.dart';
import 'package:centim/data/repositories/category_repository.dart';

void main() {
  // Dades reals de "Seguro De Vida Eloi" (Préstecs / Crèdits → Assegurances).
  const subId = '42e8d29e-38d7-4f8f-9633-b0eefca05033';
  const payerId = '4VuoK5hEdJMpaQs5hm7HQ2tHedE2';

  SubCategory seguroDeVida({bool archived = false}) => const SubCategory(
        id: subId,
        name: 'Seguro De Vida Eloi',
        monthlyBudget: 0,
        isFixed: false,
        isWatched: false,
        linkedDebtId: null,
        linkedSavingsGoalId: null,
        defaultPayerId: payerId,
        paymentDay: null,
        paymentTiming: PaymentTiming.specificDay,
      ).copyWith(archived: archived);

  Category prestecs(List<SubCategory> subs) => Category(
        id: 'cat_prestecs',
        name: 'Préstecs / Crèdits',
        icon: '💳',
        type: TransactionType.expense,
        subcategories: subs,
      );

  Category assegurances(List<SubCategory> subs) => Category(
        id: 'cat_assegurances',
        name: 'Assegurances',
        icon: '🛡️',
        type: TransactionType.expense,
        subcategories: subs,
      );

  void expectIntact(SubCategory s, {required bool archived}) {
    expect(s.id, subId, reason: 'id ha de sobreviure (clau de l\'històric)');
    expect(s.name, 'Seguro De Vida Eloi');
    expect(s.monthlyBudget, 0);
    expect(s.isFixed, false);
    expect(s.isWatched, false);
    expect(s.linkedDebtId, isNull);
    expect(s.linkedSavingsGoalId, isNull);
    expect(s.defaultPayerId, payerId); // ← el que més preocupa
    expect(s.paymentDay, isNull);
    expect(s.paymentTiming, PaymentTiming.specificDay); // ← i aquest
    expect(s.archived, archived);
  }

  test('el map arriba SENCER al pare destí', () {
    final sub = seguroDeVida();
    // Un germà amb linkedDebtId per assegurar que no el toquem.
    const germa = SubCategory(
      id: 'altre',
      name: 'Visa Or Eloi',
      monthlyBudget: 50,
      linkedDebtId: 'debt_visa_or',
    );

    final moved = applySubcategoryMove(
      from: prestecs([germa, sub]),
      to: assegurances(const []),
      sub: sub,
    );

    // Surt de l'origen, i el germà (amb el seu deute) hi queda intacte.
    expect(moved.from.subcategories.map((s) => s.id), ['altre']);
    expect(moved.from.subcategories.first.linkedDebtId, 'debt_visa_or');

    // Arriba al destí amb TOTS els camps.
    expect(moved.to.subcategories.length, 1);
    expectIntact(moved.to.subcategories.first, archived: false);
  });

  test('sobreviu al round-trip de serialització (el que desa Firestore)', () {
    final sub = seguroDeVida();
    final moved = applySubcategoryMove(
      from: prestecs([sub]),
      to: assegurances(const []),
      sub: sub,
    );

    // Firestore desa el toJson i el rellegeix amb fromJson: si algun camp es
    // perd (enums, nulls, ids), es perd aquí.
    final json = moved.to.subcategories.first.toJson();
    expect(json['defaultPayerId'], payerId);
    expect(json['paymentTiming'], 'specificDay');

    final back = SubCategory.fromJson(json);
    expectIntact(back, archived: false);
  });

  test('conserva l\'estat arxivat', () {
    final sub = seguroDeVida(archived: true);
    final moved = applySubcategoryMove(
      from: prestecs([sub]),
      to: assegurances(const []),
      sub: sub,
    );
    expectIntact(
      SubCategory.fromJson(moved.to.subcategories.first.toJson()),
      archived: true,
    );
  });

  test('no altera les subcategories que ja hi havia al destí', () {
    final sub = seguroDeVida();
    const existent = SubCategory(
      id: 'mybox',
      name: 'Mybox Asseg. Salut + Alarma + Casa + Vida',
      monthlyBudget: 275,
      isFixed: true,
    );

    final moved = applySubcategoryMove(
      from: prestecs([sub]),
      to: assegurances([existent]),
      sub: sub,
    );

    expect(moved.to.subcategories.length, 2);
    final keep = moved.to.subcategories.firstWhere((s) => s.id == 'mybox');
    expect(keep.monthlyBudget, 275);
    expect(keep.isFixed, true);
  });
}
