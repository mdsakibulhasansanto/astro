/// Feng shui Kua number from birth date and birth sex.
///
/// The feng shui year starts around 4 February, so earlier birthdays count
/// toward the previous year. Kua 5 does not exist: men take 2, women 8.
int kuaNumber(DateTime birthDate, {required bool isMale}) {
  final y = birthDate.year;
  final m = birthDate.month;
  final d = birthDate.day;
  final year = (m < 2 || (m == 2 && d < 4)) ? y - 1 : y;

  final s = _reduce(year % 100);
  var k = isMale ? (year < 2000 ? 10 - s : 9 - s) : (year < 2000 ? 5 + s : 6 + s);
  k = _reduce(k);
  if (k == 0) k = 9;
  if (k == 5) k = isMale ? 2 : 8;
  return k;
}

int _reduce(int n) {
  var v = n;
  while (v > 9) {
    v = v.toString().split('').fold(0, (a, c) => a + int.parse(c));
  }
  return v;
}
