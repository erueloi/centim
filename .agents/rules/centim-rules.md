---
trigger: always_on
---

# Regles i Context de Cèntim per a Agents IA

Ets un desenvolupador Expert en Flutter i Dart. Aquest document defineix l'arquitectura, les llibreries i les bones pràctiques per al projecte "Cèntim" (una app de finances personals basades en pressupost base zero).

## 1. Arquitectura del Projecte (Domain-Driven Design)
L'aplicació està dividida estrictament en tres capes dins de `/lib`:
- **`/domain`**: Models de dades purs i definicions d'interfícies (repositoris i serveis). NO pot contenir dependències de Flutter UI ni de bases de dades (Firebase).
- **`/data`**: Implementació dels repositoris i connexió amb l'exterior (Firebase Firestore). Aquí viuen els DTOs i la lògica de base de dades.
- **`/presentation`**: Interfície d'usuari i gestió de l'estat. Es divideix en `/screens`, `/widgets`, `/sheets` (per als bottom sheets) i `/providers` (per a l'estat).

*Regla:* La capa de Presentation MAI pot parlar directament amb Data. Sempre ho ha de fer a través dels providers que consumeixen els repositoris del Domain.

## 2. Gestió d'Estat (Riverpod)
- Utilitzem exclusivament `flutter_riverpod`.
- Afavoreix l'ús de `@riverpod` (Generador de codi) i `AsyncNotifier` o `Notifier` per als estats complexos, en lloc de `StateNotifier` antic.
- Mantingues els controladors i la lògica de negoci fora dels ginys (Widgets). Els ginys només escolten l'estat (`ref.watch`) i disparen accions (`ref.read(provider.notifier).accio()`).

## 3. Models de Dades (Freezed)
- Tots els models dins de `domain/models` han de ser immutables i utilitzar el paquet `freezed` i `json_serializable`.
- *Regla d'Or:* Sempre que modifiquis, afegeixis o eliminis un camp en un model `.dart`, HAS d'executar automàticament la comanda de generació de codi:
  `flutter pub run build_runner build --delete-conflicting-outputs`

## 4. UI i Disseny
- L'app té un tema fosc predefinit. Utilitza la paleta de colors centralitzada a `lib/core/theme/app_theme.dart`.
- Evita "Hardcodejar" colors tipus `Colors.red` als ginys; utilitza el `Theme.of(context).colorScheme`.
- Fes servir ginys petits i modulars. Si un mètode `build` té més de 100 línies, extreu les parts en sub-ginys.

## 5. Idioma i Internacionalització (l10n)
- L'app és multi-idioma (Català i Anglès). NO escriguis text directament (hardcoded) als widgets (ex: `Text("Hola")`).
- Utilitza el sistema de traducció afegint les claus als arxius `lib/l10n/app_ca.arb` i `app_en.arb`.
- Utilitza `AppLocalizations.of(context)!.clauTraduccio` per mostrar els textos.
- L'idioma principal de comunicació amb l'usuari desenvolupador és el **Català**.

## 6. Bases de Dades i Firebase
- Utilitzem Firestore. Assegura't de gestionar bé els estats de "loading" i "error" quan es fan crides asíncrones.
- Utilitza transaccions o "batch writes" de Firestore si s'han de modificar múltiples documents alhora per garantir la integritat del pressupost.