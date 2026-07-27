/// Formata un import per a un camp de text EDITABLE conservant els decimals.
///
/// Important: als camps editables no es pot fer servir `toStringAsFixed(0)`,
/// perquè en desar es rellegeix el text del camp i els cèntims es perden per
/// sempre (p. ex. un pressupost de 275,36 € quedava en 275 € només d'obrir
/// l'editor). Els enters es mostren sense decimals per no fer soroll.
///
/// Per a etiquetes de només lectura (gràfics, resums) sí que és correcte
/// arrodonir: allà no hi ha risc de perdre dades.
String editableAmountText(double v) =>
    v % 1 == 0 ? v.toStringAsFixed(0) : v.toString();

/// Llegeix un import escrit per l'usuari acceptant els DOS separadors decimals.
///
/// El teclat numèric en català/castellà dona coma ("275,36") però
/// `double.tryParse` només entén el punt i retorna null → si el resultat es
/// desava amb `?? 0.0`, escriure una coma deixava l'import a ZERO en silenci.
/// Retorna null si el text no és un número (per poder distingir "buit o
/// invàlid" de "zero" allà on importi).
double? parseEditableAmount(String text) {
  final t = text.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}
