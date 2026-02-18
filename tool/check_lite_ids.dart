void main() {
  const maxSafe = 9007199254740991;

  final candidates = [
    {'name': 'Bgt', 'col': -9068991778459992130, 'idx': 8193695471701937315},
    {'name': 'Bud', 'col': -5907598319411133192, 'idx': -4906094122524121629},
    // I need to read the rest of the file for others, but let's check these first
  ];

  for (final cand in candidates) {
    bool colSafe = (cand['col'] as int).abs() <= maxSafe;
    bool idxSafe = (cand['idx'] as int).abs() <= maxSafe;
    // ignore: avoid_print
    print('${cand['name']}: ColSafe=$colSafe, IdxSafe=$idxSafe');
  }
}
