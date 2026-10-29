/// Normalises an angle to 0–360 degrees.
double normalizeDegrees(double a) => ((a % 360) + 360) % 360;

/// Position inside a sign, e.g. `14°07′`.
String formatSignDegree(double longitude) {
  final x = normalizeDegrees(longitude) % 30;
  var d = x.floor();
  var m = ((x - d) * 60).round();
  if (m == 60) {
    d++;
    m = 0;
  }
  return '$d°${m.toString().padLeft(2, '0')}′';
}

/// `yyyy-MM-dd`, the format Postgres `date` columns use.
String formatIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `15 Jun 1990`.
String formatReadableDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Trims a number for display: 12.0 → "12", 12.5 → "12.5".
String formatNumber(num v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
