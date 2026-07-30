/// Normalització compartida pels imports, la deduplicació, l'autoaprenentatge
/// i les agrupacions de moviments.
String normalizeTransactionConcept(String concept) =>
    concept.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Clau sense referències numèriques ni puntuació.
///
/// Conserva tots els tokens perquè les regles explícites puguin distingir
/// conceptes diferents del mateix emissor. La coincidència de comerç més
/// flexible viu a [conceptKeysRepresentSameMerchant].
String transactionConceptKey(String concept) {
  return normalizeTransactionConcept(concept)
      .replaceAll(RegExp(r'[^a-zà-öø-ÿ]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Indica si dues claus normalitzades representen probablement el mateix
/// comerç/concepte estable.
///
/// Exemples:
///  - `consum` ↔ `consum rubi cald`
///  - `plus fresc` ↔ `plus fresc balaguer`
///  - `devolucio plus fresc` ↔ `plus fresc`
///
/// Un únic token només és prou discriminant si té almenys cinc caràcters.
/// Amb prefixes curts o genèrics (p. ex. `plus`) n'exigim dos.
bool conceptKeysRepresentSameMerchant(String leftKey, String rightKey) {
  final left = _identityTokens(leftKey);
  final right = _identityTokens(rightKey);
  if (left.isEmpty || right.isEmpty) return false;
  if (_sameTokens(left, right)) return true;

  final shorter = left.length <= right.length ? left : right;
  final longer = identical(shorter, left) ? right : left;
  final requiredTokens =
      shorter.length == 1 && shorter.first.length >= 5 ? 1 : 2;
  if (shorter.length < requiredTokens) return false;

  return _containsTokenSequence(longer, shorter.take(requiredTokens).toList());
}

/// Retorna un candidat difús només quan tots els conceptes coincidents apunten
/// al mateix destí. Evita que un mateix emissor amb conceptes diferents
/// reaprengui una categoria equivocada.
T? unambiguousMerchantCandidate<T>({
  required String key,
  required Map<String, T> candidates,
  required Object Function(T candidate) targetKey,
}) {
  final matches = candidates.entries
      .where(
        (entry) => conceptKeysRepresentSameMerchant(key, entry.key),
      )
      .map((entry) => entry.value)
      .toList();
  if (matches.isEmpty) return null;

  final targets = matches.map(targetKey).toSet();
  return targets.length == 1 ? matches.first : null;
}

/// Etiqueta comuna i llegible per a un grup de claus coincidents.
String commonMerchantLabel(Iterable<String> keys) {
  final tokenLists =
      keys.map(_identityTokens).where((tokens) => tokens.isNotEmpty).toList();
  if (tokenLists.isEmpty) return 'SENSE CONCEPTE';

  var common = List<String>.from(tokenLists.first);
  for (final tokens in tokenLists.skip(1)) {
    var length = 0;
    while (length < common.length &&
        length < tokens.length &&
        common[length] == tokens[length]) {
      length++;
    }
    common = common.take(length).toList();
    if (common.isEmpty) break;
  }

  if (common.isNotEmpty) return common.join(' ').toUpperCase();
  tokenLists.sort((a, b) => a.length.compareTo(b.length));
  return tokenLists.first.join(' ').toUpperCase();
}

const _refundPrefixes = {
  'devolucio',
  'devolució',
  'devolucion',
  'devolución',
  'refund',
  'reemborsament',
  'reembolso',
};

List<String> _identityTokens(String key) {
  final tokens = transactionConceptKey(key)
      .split(' ')
      .where((token) => token.isNotEmpty)
      .toList();
  while (tokens.isNotEmpty && _refundPrefixes.contains(tokens.first)) {
    tokens.removeAt(0);
  }
  return tokens;
}

bool _sameTokens(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

bool _containsTokenSequence(List<String> haystack, List<String> needle) {
  if (needle.isEmpty || needle.length > haystack.length) return false;
  for (var start = 0; start <= haystack.length - needle.length; start++) {
    var matches = true;
    for (var offset = 0; offset < needle.length; offset++) {
      if (haystack[start + offset] != needle[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}
