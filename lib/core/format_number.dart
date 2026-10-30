/// 7.333 → «7,3». Один формат на все экраны.
String formatAverage(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');

/// 1.43 → «+1,4», -0.8 → «−0,8», 0.02 → «0,0».
String formatImpact(double value) {
  final text = formatAverage(value.abs());
  if (text == '0,0') return text;
  return value > 0 ? '+$text' : '−$text';
}