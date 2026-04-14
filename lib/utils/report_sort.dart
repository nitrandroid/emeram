// lib/utils/report_sort.dart

import 'slovak_sort.dart';

/// Triedenie reportov podľa percenta účasti.
/// 
/// Pravidlá:
/// - primárne: percento (rešpektuje ascending)
/// - sekundárne: priezvisko (VŽDY vzostupne)
/// - terciárne: krstné meno (VŽDY vzostupne)
int compareByAttendancePercent(
  Map<String, dynamic> a,
  Map<String, dynamic> b, {
  required bool ascending,
}) {
  final pA = _percent(a);
  final pB = _percent(b);

  // 1️⃣ percento (ASC / DESC)
  int cmp = pA.compareTo(pB);
  if (cmp != 0) {
    return ascending ? cmp : -cmp;
  }

  // 2️⃣ priezvisko (VŽDY vzostupne)
  cmp = slovakCompare(
    a['lastName'] as String,
    b['lastName'] as String,
  );
  if (cmp != 0) return cmp;

  // 3️⃣ krstné meno (VŽDY vzostupne)
  return slovakCompare(
    a['firstName'] as String,
    b['firstName'] as String,
  );
}

/// Triedenie reportov podľa mena.
///
/// Pravidlá:
/// - primárne: priezvisko (rešpektuje ascending)
/// - sekundárne: krstné meno (VŽDY vzostupne)
int compareByName(
  Map<String, dynamic> a,
  Map<String, dynamic> b, {
  required bool ascending,
}) {
  // 1️⃣ priezvisko (ASC / DESC)
  int cmp = slovakCompare(
    a['lastName'] as String,
    b['lastName'] as String,
  );
  if (cmp != 0) {
    return ascending ? cmp : -cmp;
  }

  // 2️⃣ krstné meno (VŽDY vzostupne)
  return slovakCompare(
    a['firstName'] as String,
    b['firstName'] as String,
  );
}

/// Interný výpočet percenta účasti
double _percent(Map<String, dynamic> r) {
  final total = r['total'] as int? ?? 0;
  if (total == 0) return 0.0;
  return (r['attended'] as int) / total;
}