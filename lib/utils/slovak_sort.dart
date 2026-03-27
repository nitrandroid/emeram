// lib/utils/slovak_sort.dart

/*
  Slovenské triedenie so správnou podporou písmen „DZ“, „DŽ“ a „CH“.
  Poradie týchto grafém vychádza zo Slovenskej abecedy podľa normy
  Jazykovedného ústavu Ľudovíta Štúra SAV.

  Triedenie sa používa jednotne v celej aplikácii – pre kategórie,
  osoby aj skladby. Poskytuje konzistentné, prehľadné a normatívne
  správne zoradenie textov.
*/

const Map<String, int> skOrder = {
  'a': 0,
  'á': 1,
  'ä': 2,
  'b': 3,
  'c': 4,
  'č': 5,
  'd': 6,
  'ď': 7,
  'dz': 8,
  'dž': 9,
  'e': 10,
  'é': 11,
  'f': 12,
  'g': 13,
  'h': 14,
  'ch': 15,
  'i': 16,
  'í': 17,
  'j': 18,
  'k': 19,
  'l': 20,
  'ĺ': 21,
  'ľ': 22,
  'm': 23,
  'n': 24,
  'ň': 25,
  'o': 26,
  'ó': 27,
  'ô': 28,
  'p': 29,
  'q': 30,
  'r': 31,
  'ŕ': 32,
  's': 33,
  'š': 34,
  't': 35,
  'ť': 36,
  'u': 37,
  'ú': 38,
  'v': 39,
  'w': 40,
  'x': 41,
  'y': 42,
  'ý': 43,
  'z': 44,
  'ž': 45,
};

/// Pomocná funkcia, ktorá vyberie ďalšiu „slovenskú grafému“.
/// Spracuje správne DŽ, DZ aj CH.
String nextLetter(String s, int index) {
  // DŽ
  if (index + 1 < s.length && s[index] == 'd' && s[index + 1] == 'ž') {
    return 'dž';
  }
  // DZ
  if (index + 1 < s.length && s[index] == 'd' && s[index + 1] == 'z') {
    return 'dz';
  }
  // CH
  if (index + 1 < s.length && s[index] == 'c' && s[index + 1] == 'h') {
    return 'ch';
  }
  // Jednopísmenové grafémy
  return s[index];
}

/// Porovnanie dvoch reťazcov podľa slovenskej abecedy.
/// Zohľadňuje viacpísmenové grafémy: DZ, DŽ a CH.
int slovakCompare(String a, String b) {
  final aa = a.toLowerCase();
  final bb = b.toLowerCase();

  int i = 0;
  int j = 0;

  while (i < aa.length && j < bb.length) {
    final ca = nextLetter(aa, i);
    final cb = nextLetter(bb, j);

    final ia = skOrder[ca];
    final ib = skOrder[cb];

    if (ia != null && ib != null) {
      if (ia != ib) return ia.compareTo(ib);
    } else {
      // fallback porovnanie znakov – veľmi zriedkavé
      final cmp = ca.compareTo(cb);
      if (cmp != 0) return cmp;
    }

    // posun o dĺžku grafémy (1 alebo 2 znaky)
    i += ca.length;
    j += cb.length;
  }

  return aa.length.compareTo(bb.length);
}

/// Komparátorový reťazec.
/// Umožňuje triediť podľa viacerých kritérií postupne.
///
/// Napr.:
///  - priezvisko
///  - potom meno
///  - potom ID
///
/// Keď prvé kritérium nerozhodne, použije sa ďalšie.
int chainCompare<T>(List<int Function(T, T)> chain, T a, T b) {
  for (final comparator in chain) {
    final r = comparator(a, b);
    if (r != 0) return r;
  }
  return 0;
}

/// Vzostupné slovenské triedenie (A → Ž).
int sortAsc(String a, String b) => slovakCompare(a, b);

/// Zostupné slovenské triedenie (Ž → A).
int sortDesc(String a, String b) => -slovakCompare(a, b);

/// SATB triedenie kategórií (S, A, T, B + ostatné podľa SK sort)
List<T> sortSatb<T>(
  List<T> items,
  String Function(T) getName,
) {
  const satbOrder = ["Soprán", "Alt", "Tenor", "Bas"];

  final satb = items.where((e) => satbOrder.contains(getName(e))).toList()
    ..sort((a, b) =>
        satbOrder.indexOf(getName(a)).compareTo(satbOrder.indexOf(getName(b))));

  final other = items.where((e) => !satbOrder.contains(getName(e))).toList()
    ..sort((a, b) => slovakCompare(getName(a), getName(b)));

  return [...satb, ...other];
}

/// Odstránenie diakritiky pre potreby vyhľadávania.
/// Triedenie ostáva slovenské – toto slúži len na fulltext search.
String removeDiacritics(String input) {
  const withDia = 'áäčďéíĺľňóôŕšťúýžÁÄČĎÉÍĹĽŇÓÔŔŠŤÚÝŽ';
  const withoutDia = 'aacdeillnoorstuyzAACDEILLNOORSTUYZ';

  String result = input;
  for (int i = 0; i < withDia.length; i++) {
    result = result.replaceAll(withDia[i], withoutDia[i]);
  }

  return result;
}

/// Porovná dva reťazce pre vyhľadávanie.
/// Ignoruje diakritiku a veľkosť písmen.
/// Nepoužíva sa pri triedení – iba pri filtrovaní / search.
bool matchesSearch(String original, String search) {
  if (search.trim().isEmpty) return true;

  final normOriginal = removeDiacritics(original.toLowerCase());
  final normSearch = removeDiacritics(search.toLowerCase());

  return normOriginal.contains(normSearch);
}
