/// WHO Child Growth Standards Reference Data (LMS Parameters).
/// Source: World Health Organization Child Growth Standards (2006).
/// Contains LMS values (Lambda = Box-Cox power, Mu = Median, Sigma = Coefficient of Variation)
/// for Weight-for-Age (WAZ), Length/Height-for-Age (HAZ), and Weight-for-Length/Height (WFHZ).
library;

class LmsPoint {
  final double x; // Age in months (WAZ/HAZ) or Length/Height in cm (WFHZ)
  final double l; // Box-Cox power L
  final double m; // Median M
  final double s; // Generalized CV S
  final double sd3neg;
  final double sd2neg;
  final double sd1neg;
  final double sd0;
  final double sd1pos;
  final double sd2pos;
  final double sd3pos;

  const LmsPoint({
    required this.x,
    required this.l,
    required this.m,
    required this.s,
    required this.sd3neg,
    required this.sd2neg,
    required this.sd1neg,
    required this.sd0,
    required this.sd1pos,
    required this.sd2pos,
    required this.sd3pos,
  });
}

class WhoStandardsData {
  // ── Weight-for-Age (WAZ) Boys (Months 0 to 60) ──────────────────────────────
  static const List<LmsPoint> wazBoys = [
    LmsPoint(x: 0, l: 0.3487, m: 3.346, s: 0.14602, sd3neg: 2.1, sd2neg: 2.5, sd1neg: 2.9, sd0: 3.3, sd1pos: 3.9, sd2pos: 4.4, sd3pos: 5.0),
    LmsPoint(x: 1, l: 0.2297, m: 4.471, s: 0.13395, sd3neg: 2.9, sd2neg: 3.4, sd1neg: 3.9, sd0: 4.5, sd1pos: 5.1, sd2pos: 5.8, sd3pos: 6.6),
    LmsPoint(x: 2, l: 0.1462, m: 5.568, s: 0.12423, sd3neg: 3.8, sd2neg: 4.3, sd1neg: 4.9, sd0: 5.6, sd1pos: 6.3, sd2pos: 7.1, sd3pos: 8.0),
    LmsPoint(x: 3, l: 0.0825, m: 6.386, s: 0.11674, sd3neg: 4.4, sd2neg: 5.0, sd1neg: 5.7, sd0: 6.4, sd1pos: 7.2, sd2pos: 8.0, sd3pos: 9.0),
    LmsPoint(x: 4, l: 0.0319, m: 7.028, s: 0.11089, sd3neg: 4.9, sd2neg: 5.6, sd1neg: 6.2, sd0: 7.0, sd1pos: 7.8, sd2pos: 8.7, sd3pos: 9.7),
    LmsPoint(x: 5, l: -0.0097, m: 7.545, s: 0.10629, sd3neg: 5.3, sd2neg: 6.0, sd1neg: 6.7, sd0: 7.5, sd1pos: 8.4, sd2pos: 9.3, sd3pos: 10.4),
    LmsPoint(x: 6, l: -0.0445, m: 7.949, s: 0.10266, sd3neg: 5.7, sd2neg: 6.4, sd1neg: 7.1, sd0: 7.9, sd1pos: 8.8, sd2pos: 9.8, sd3pos: 10.9),
    LmsPoint(x: 7, l: -0.0740, m: 8.283, s: 0.09977, sd3neg: 5.9, sd2neg: 6.7, sd1neg: 7.4, sd0: 8.3, sd1pos: 9.2, sd2pos: 10.3, sd3pos: 11.4),
    LmsPoint(x: 8, l: -0.0994, m: 8.572, s: 0.09746, sd3neg: 6.2, sd2neg: 6.9, sd1neg: 7.7, sd0: 8.6, sd1pos: 9.6, sd2pos: 10.7, sd3pos: 11.9),
    LmsPoint(x: 9, l: -0.1215, m: 8.832, s: 0.09562, sd3neg: 6.4, sd2neg: 7.2, sd1neg: 8.0, sd0: 8.8, sd1pos: 9.9, sd2pos: 11.0, sd3pos: 12.3),
    LmsPoint(x: 10, l: -0.1409, m: 9.073, s: 0.09415, sd3neg: 6.6, sd2neg: 7.4, sd1neg: 8.2, sd0: 9.1, sd1pos: 10.2, sd2pos: 11.4, sd3pos: 12.7),
    LmsPoint(x: 11, l: -0.1581, m: 9.301, s: 0.09299, sd3neg: 6.8, sd2neg: 7.6, sd1neg: 8.4, sd0: 9.3, sd1pos: 10.5, sd2pos: 11.7, sd3pos: 13.0),
    LmsPoint(x: 12, l: -0.1734, m: 9.521, s: 0.09207, sd3neg: 6.9, sd2neg: 7.7, sd1neg: 8.6, sd0: 9.5, sd1pos: 10.8, sd2pos: 12.0, sd3pos: 13.3),
    LmsPoint(x: 15, l: -0.2109, m: 10.138, s: 0.09071, sd3neg: 7.4, sd2neg: 8.3, sd1neg: 9.2, sd0: 10.1, sd1pos: 11.5, sd2pos: 12.8, sd3pos: 14.3),
    LmsPoint(x: 18, l: -0.2383, m: 10.697, s: 0.09054, sd3neg: 7.8, sd2neg: 8.8, sd1neg: 9.7, sd0: 10.7, sd1pos: 12.2, sd2pos: 13.7, sd3pos: 15.3),
    LmsPoint(x: 21, l: -0.2590, m: 11.218, s: 0.09115, sd3neg: 8.2, sd2neg: 9.2, sd1neg: 10.2, sd0: 11.2, sd1pos: 12.8, sd2pos: 14.4, sd3pos: 16.2),
    LmsPoint(x: 24, l: -0.2747, m: 11.713, s: 0.09228, sd3neg: 8.6, sd2neg: 9.7, sd1neg: 10.6, sd0: 11.7, sd1pos: 13.3, sd2pos: 15.1, sd3pos: 17.1),
    LmsPoint(x: 30, l: -0.2974, m: 12.678, s: 0.09569, sd3neg: 9.4, sd2neg: 10.5, sd1neg: 11.5, sd0: 12.7, sd1pos: 14.4, sd2pos: 16.4, sd3pos: 18.7),
    LmsPoint(x: 36, l: -0.3138, m: 13.626, s: 0.09995, sd3neg: 10.0, sd2neg: 11.3, sd1neg: 12.4, sd0: 13.6, sd1pos: 15.6, sd2pos: 17.8, sd3pos: 20.4),
    LmsPoint(x: 42, l: -0.3270, m: 14.567, s: 0.10471, sd3neg: 10.6, sd2neg: 12.0, sd1neg: 13.2, sd0: 14.6, sd1pos: 16.7, sd2pos: 19.2, sd3pos: 22.1),
    LmsPoint(x: 48, l: -0.3384, m: 15.503, s: 0.10982, sd3neg: 11.2, sd2neg: 12.7, sd1neg: 14.0, sd0: 15.5, sd1pos: 17.8, sd2pos: 20.6, sd3pos: 23.9),
    LmsPoint(x: 54, l: -0.3486, m: 16.435, s: 0.11516, sd3neg: 11.8, sd2neg: 13.4, sd1neg: 14.8, sd0: 16.4, sd1pos: 19.0, sd2pos: 22.0, sd3pos: 25.7),
    LmsPoint(x: 60, l: -0.3580, m: 17.365, s: 0.12065, sd3neg: 12.4, sd2neg: 14.1, sd1neg: 15.6, sd0: 17.4, sd1pos: 20.1, sd2pos: 23.5, sd3pos: 27.6),
  ];

  // ── Weight-for-Age (WAZ) Girls (Months 0 to 60) ─────────────────────────────
  static const List<LmsPoint> wazGirls = [
    LmsPoint(x: 0, l: 0.3809, m: 3.232, s: 0.14171, sd3neg: 2.0, sd2neg: 2.4, sd1neg: 2.8, sd0: 3.2, sd1pos: 3.7, sd2pos: 4.2, sd3pos: 4.8),
    LmsPoint(x: 1, l: 0.2647, m: 4.187, s: 0.13374, sd3neg: 2.7, sd2neg: 3.2, sd1neg: 3.6, sd0: 4.2, sd1pos: 4.8, sd2pos: 5.5, sd3pos: 6.2),
    LmsPoint(x: 2, l: 0.1777, m: 5.128, s: 0.12648, sd3neg: 3.4, sd2neg: 3.9, sd1neg: 4.5, sd0: 5.1, sd1pos: 5.8, sd2pos: 6.6, sd3pos: 7.5),
    LmsPoint(x: 3, l: 0.1090, m: 5.845, s: 0.12040, sd3neg: 4.0, sd2neg: 4.5, sd1neg: 5.2, sd0: 5.8, sd1pos: 6.6, sd2pos: 7.5, sd3pos: 8.5),
    LmsPoint(x: 4, l: 0.0537, m: 6.424, s: 0.11543, sd3neg: 4.4, sd2neg: 5.0, sd1neg: 5.7, sd0: 6.4, sd1pos: 7.3, sd2pos: 8.2, sd3pos: 9.3),
    LmsPoint(x: 5, l: 0.0084, m: 6.899, s: 0.11136, sd3neg: 4.8, sd2neg: 5.4, sd1neg: 6.1, sd0: 6.9, sd1pos: 7.8, sd2pos: 8.8, sd3pos: 10.0),
    LmsPoint(x: 6, l: -0.0294, m: 7.297, s: 0.10800, sd3neg: 5.1, sd2neg: 5.7, sd1neg: 6.5, sd0: 7.3, sd1pos: 8.2, sd2pos: 9.3, sd3pos: 10.6),
    LmsPoint(x: 7, l: -0.0617, m: 7.641, s: 0.10521, sd3neg: 5.3, sd2neg: 6.0, sd1neg: 6.8, sd0: 7.6, sd1pos: 8.6, sd2pos: 9.8, sd3pos: 11.1),
    LmsPoint(x: 8, l: -0.0898, m: 7.947, s: 0.10287, sd3neg: 5.6, sd2neg: 6.3, sd1neg: 7.1, sd0: 7.9, sd1pos: 9.0, sd2pos: 10.2, sd3pos: 11.6),
    LmsPoint(x: 9, l: -0.1147, m: 8.225, s: 0.10090, sd3neg: 5.8, sd2neg: 6.5, sd1neg: 7.3, sd0: 8.2, sd1pos: 9.3, sd2pos: 10.5, sd3pos: 12.0),
    LmsPoint(x: 10, l: -0.1368, m: 8.483, s: 0.09923, sd3neg: 6.0, sd2neg: 6.7, sd1neg: 7.5, sd0: 8.5, sd1pos: 9.6, sd2pos: 10.9, sd3pos: 12.4),
    LmsPoint(x: 11, l: -0.1565, m: 8.725, s: 0.09782, sd3neg: 6.1, sd2neg: 6.9, sd1neg: 7.8, sd0: 8.7, sd1pos: 9.9, sd2pos: 11.2, sd3pos: 12.8),
    LmsPoint(x: 12, l: -0.1741, m: 8.954, s: 0.09664, sd3neg: 6.3, sd2neg: 7.0, sd1neg: 8.0, sd0: 9.0, sd1pos: 10.2, sd2pos: 11.5, sd3pos: 13.2),
    LmsPoint(x: 15, l: -0.2173, m: 9.584, s: 0.09457, sd3neg: 6.7, sd2neg: 7.6, sd1neg: 8.5, sd0: 9.6, sd1pos: 10.9, sd2pos: 12.4, sd3pos: 14.1),
    LmsPoint(x: 18, l: -0.2486, m: 10.154, s: 0.09425, sd3neg: 7.2, sd2neg: 8.1, sd1neg: 9.1, sd0: 10.2, sd1pos: 11.6, sd2pos: 13.2, sd3pos: 15.1),
    LmsPoint(x: 21, l: -0.2717, m: 10.686, s: 0.09520, sd3neg: 7.6, sd2neg: 8.6, sd1neg: 9.6, sd0: 10.7, sd1pos: 12.2, sd2pos: 14.0, sd3pos: 16.0),
    LmsPoint(x: 24, l: -0.2893, m: 11.196, s: 0.09703, sd3neg: 8.1, sd2neg: 9.0, sd1neg: 10.1, sd0: 11.2, sd1pos: 12.8, sd2pos: 14.8, sd3pos: 16.9),
    LmsPoint(x: 30, l: -0.3151, m: 12.185, s: 0.10214, sd3neg: 8.8, sd2neg: 9.8, sd1neg: 10.9, sd0: 12.2, sd1pos: 14.1, sd2pos: 16.2, sd3pos: 18.7),
    LmsPoint(x: 36, l: -0.3341, m: 13.141, s: 0.10825, sd3neg: 9.4, sd2neg: 10.5, sd1neg: 11.8, sd0: 13.1, sd1pos: 15.3, sd2pos: 17.7, sd3pos: 20.6),
    LmsPoint(x: 42, l: -0.3492, m: 14.075, s: 0.11494, sd3neg: 10.0, sd2neg: 11.2, sd1neg: 12.6, sd0: 14.1, sd1pos: 16.5, sd2pos: 19.2, sd3pos: 22.5),
    LmsPoint(x: 48, l: -0.3619, m: 14.996, s: 0.12200, sd3neg: 10.5, sd2neg: 11.9, sd1neg: 13.4, sd0: 15.0, sd1pos: 17.7, sd2pos: 20.7, sd3pos: 24.4),
    LmsPoint(x: 54, l: -0.3730, m: 15.908, s: 0.12929, sd3neg: 11.1, sd2neg: 12.6, sd1neg: 14.2, sd0: 15.9, sd1pos: 18.9, sd2pos: 22.3, sd3pos: 26.5),
    LmsPoint(x: 60, l: -0.3828, m: 16.815, s: 0.13670, sd3neg: 11.6, sd2neg: 13.3, sd1neg: 15.0, sd0: 16.8, sd1pos: 20.1, sd2pos: 23.9, sd3pos: 28.5),
  ];

  // ── Length/Height-for-Age (HAZ) Boys (Months 0 to 60) ───────────────────────
  static const List<LmsPoint> hazBoys = [
    LmsPoint(x: 0, l: 1.0, m: 49.88, s: 0.03795, sd3neg: 44.2, sd2neg: 46.1, sd1neg: 48.0, sd0: 49.9, sd1pos: 51.8, sd2pos: 53.7, sd3pos: 55.6),
    LmsPoint(x: 3, l: 1.0, m: 61.42, s: 0.03450, sd3neg: 55.1, sd2neg: 57.2, sd1neg: 59.3, sd0: 61.4, sd1pos: 63.5, sd2pos: 65.7, sd3pos: 67.8),
    LmsPoint(x: 6, l: 1.0, m: 67.62, s: 0.03360, sd3neg: 60.8, sd2neg: 63.1, sd1neg: 65.4, sd0: 67.6, sd1pos: 69.9, sd2pos: 72.2, sd3pos: 74.4),
    LmsPoint(x: 9, l: 1.0, m: 71.96, s: 0.03332, sd3neg: 64.8, sd2neg: 67.2, sd1neg: 69.6, sd0: 72.0, sd1pos: 74.4, sd2pos: 76.7, sd3pos: 79.1),
    LmsPoint(x: 12, l: 1.0, m: 75.75, s: 0.03328, sd3neg: 68.2, sd2neg: 70.7, sd1neg: 73.2, sd0: 75.7, sd1pos: 78.3, sd2pos: 80.8, sd3pos: 83.3),
    LmsPoint(x: 18, l: 1.0, m: 82.31, s: 0.03358, sd3neg: 74.0, sd2neg: 76.8, sd1neg: 79.5, sd0: 82.3, sd1pos: 85.1, sd2pos: 87.8, sd3pos: 90.6),
    LmsPoint(x: 24, l: 1.0, m: 87.82, s: 0.03434, sd3neg: 78.8, sd2neg: 81.8, sd1neg: 84.8, sd0: 87.8, sd1pos: 90.8, sd2pos: 93.9, sd3pos: 96.9),
    LmsPoint(x: 36, l: 1.0, m: 96.14, s: 0.03668, sd3neg: 85.6, sd2neg: 89.1, sd1neg: 92.6, sd0: 96.1, sd1pos: 99.7, sd2pos: 103.2, sd3pos: 106.7),
    LmsPoint(x: 48, l: 1.0, m: 103.32, s: 0.03920, sd3neg: 91.2, sd2neg: 95.2, sd1neg: 99.3, sd0: 103.3, sd1pos: 107.4, sd2pos: 111.4, sd3pos: 115.5),
    LmsPoint(x: 60, l: 1.0, m: 110.02, s: 0.04166, sd3neg: 96.3, sd2neg: 100.9, sd1neg: 105.4, sd0: 110.0, sd1pos: 114.6, sd2pos: 119.2, sd3pos: 123.8),
  ];

  // ── Length/Height-for-Age (HAZ) Girls (Months 0 to 60) ──────────────────────
  static const List<LmsPoint> hazGirls = [
    LmsPoint(x: 0, l: 1.0, m: 49.15, s: 0.03795, sd3neg: 43.6, sd2neg: 45.4, sd1neg: 47.3, sd0: 49.1, sd1pos: 51.0, sd2pos: 52.9, sd3pos: 54.7),
    LmsPoint(x: 3, l: 1.0, m: 59.84, s: 0.03460, sd3neg: 53.6, sd2neg: 55.7, sd1neg: 57.8, sd0: 59.8, sd1pos: 61.9, sd2pos: 64.0, sd3pos: 66.1),
    LmsPoint(x: 6, l: 1.0, m: 65.73, s: 0.03370, sd3neg: 59.1, sd2neg: 61.3, sd1neg: 63.5, sd0: 65.7, sd1pos: 68.0, sd2pos: 70.2, sd3pos: 72.4),
    LmsPoint(x: 9, l: 1.0, m: 70.14, s: 0.03340, sd3neg: 63.1, sd2neg: 65.5, sd1neg: 67.8, sd0: 70.1, sd1pos: 72.5, sd2pos: 74.8, sd3pos: 77.2),
    LmsPoint(x: 12, l: 1.0, m: 74.02, s: 0.03340, sd3neg: 66.6, sd2neg: 69.1, sd1neg: 71.5, sd0: 74.0, sd1pos: 76.5, sd2pos: 79.0, sd3pos: 81.4),
    LmsPoint(x: 18, l: 1.0, m: 80.70, s: 0.03380, sd3neg: 72.5, sd2neg: 75.2, sd1neg: 78.0, sd0: 80.7, sd1pos: 83.4, sd2pos: 86.2, sd3pos: 88.9),
    LmsPoint(x: 24, l: 1.0, m: 86.44, s: 0.03470, sd3neg: 77.4, sd2neg: 80.4, sd1neg: 83.4, sd0: 86.4, sd1pos: 89.4, sd2pos: 92.5, sd3pos: 95.5),
    LmsPoint(x: 36, l: 1.0, m: 95.12, s: 0.03710, sd3neg: 84.5, sd2neg: 88.1, sd1neg: 91.6, sd0: 95.1, sd1pos: 98.6, sd2pos: 102.2, sd3pos: 105.7),
    LmsPoint(x: 48, l: 1.0, m: 102.70, s: 0.03960, sd3neg: 90.5, sd2neg: 94.6, sd1neg: 98.7, sd0: 102.7, sd1pos: 106.8, sd2pos: 110.8, sd3pos: 114.9),
    LmsPoint(x: 60, l: 1.0, m: 109.40, s: 0.04210, sd3neg: 95.6, sd2neg: 100.2, sd1neg: 104.8, sd0: 109.4, sd1pos: 114.0, sd2pos: 118.6, sd3pos: 123.2),
  ];

  // ── Weight-for-Length/Height (WFHZ) Boys (45 cm to 120 cm) ───────────────────
  static const List<LmsPoint> wfhzBoys = [
    LmsPoint(x: 45.0, l: -0.3833, m: 2.434, s: 0.09115, sd3neg: 1.9, sd2neg: 2.0, sd1neg: 2.2, sd0: 2.4, sd1pos: 2.7, sd2pos: 2.9, sd3pos: 3.2),
    LmsPoint(x: 50.0, l: -0.3833, m: 3.332, s: 0.09115, sd3neg: 2.5, sd2neg: 2.8, sd1neg: 3.0, sd0: 3.3, sd1pos: 3.6, sd2pos: 4.0, sd3pos: 4.4),
    LmsPoint(x: 55.0, l: -0.3833, m: 4.544, s: 0.08900, sd3neg: 3.5, sd2neg: 3.8, sd1neg: 4.2, sd0: 4.5, sd1pos: 5.0, sd2pos: 5.4, sd3pos: 6.0),
    LmsPoint(x: 60.0, l: -0.3833, m: 5.923, s: 0.08685, sd3neg: 4.6, sd2neg: 5.0, sd1neg: 5.4, sd0: 5.9, sd1pos: 6.5, sd2pos: 7.1, sd3pos: 7.7),
    LmsPoint(x: 65.0, l: -0.3833, m: 7.378, s: 0.08518, sd3neg: 5.8, sd2neg: 6.3, sd1neg: 6.8, sd0: 7.4, sd1pos: 8.0, sd2pos: 8.7, sd3pos: 9.5),
    LmsPoint(x: 70.0, l: -0.3833, m: 8.647, s: 0.08447, sd3neg: 6.9, sd2neg: 7.4, sd1neg: 8.0, sd0: 8.6, sd1pos: 9.4, sd2pos: 10.2, sd3pos: 11.1),
    LmsPoint(x: 75.0, l: -0.3833, m: 9.683, s: 0.08470, sd3neg: 7.7, sd2neg: 8.3, sd1neg: 9.0, sd0: 9.7, sd1pos: 10.5, sd2pos: 11.5, sd3pos: 12.5),
    LmsPoint(x: 80.0, l: -0.3833, m: 10.606, s: 0.08573, sd3neg: 8.5, sd2neg: 9.1, sd1neg: 9.8, sd0: 10.6, sd1pos: 11.5, sd2pos: 12.6, sd3pos: 13.7),
    LmsPoint(x: 85.0, l: -0.3833, m: 11.644, s: 0.08745, sd3neg: 9.3, sd2neg: 10.0, sd1neg: 10.8, sd0: 11.6, sd1pos: 12.7, sd2pos: 13.9, sd3pos: 15.2),
    LmsPoint(x: 90.0, l: -0.3833, m: 12.791, s: 0.08985, sd3neg: 10.1, sd2neg: 10.9, sd1neg: 11.8, sd0: 12.8, sd1pos: 14.0, sd2pos: 15.3, sd3pos: 16.9),
    LmsPoint(x: 95.0, l: -0.3833, m: 14.024, s: 0.09278, sd3neg: 11.0, sd2neg: 11.9, sd1neg: 12.9, sd0: 14.0, sd1pos: 15.4, sd2pos: 16.9, sd3pos: 18.7),
    LmsPoint(x: 100.0, l: -0.3833, m: 15.367, s: 0.09614, sd3neg: 11.9, sd2neg: 12.9, sd1neg: 14.1, sd0: 15.4, sd1pos: 16.9, sd2pos: 18.7, sd3pos: 20.8),
    LmsPoint(x: 105.0, l: -0.3833, m: 16.840, s: 0.09988, sd3neg: 12.9, sd2neg: 14.1, sd1neg: 15.4, sd0: 16.8, sd1pos: 18.6, sd2pos: 20.7, sd3pos: 23.1),
    LmsPoint(x: 110.0, l: -0.3833, m: 18.460, s: 0.10397, sd3neg: 14.0, sd2neg: 15.3, sd1neg: 16.8, sd0: 18.5, sd1pos: 20.5, sd2pos: 22.9, sd3pos: 25.8),
    LmsPoint(x: 115.0, l: -0.3833, m: 20.244, s: 0.10839, sd3neg: 15.1, sd2neg: 16.6, sd1neg: 18.3, sd0: 20.2, sd1pos: 22.6, sd2pos: 25.4, sd3pos: 28.8),
    LmsPoint(x: 120.0, l: -0.3833, m: 22.203, s: 0.11309, sd3neg: 16.3, sd2neg: 18.0, sd1neg: 20.0, sd0: 22.2, sd1pos: 24.9, sd2pos: 28.2, sd3pos: 32.2),
  ];

  // ── Weight-for-Length/Height (WFHZ) Girls (45 cm to 120 cm) ──────────────────
  static const List<LmsPoint> wfhzGirls = [
    LmsPoint(x: 45.0, l: -0.3833, m: 2.379, s: 0.08985, sd3neg: 1.8, sd2neg: 2.0, sd1neg: 2.2, sd0: 2.4, sd1pos: 2.6, sd2pos: 2.8, sd3pos: 3.1),
    LmsPoint(x: 50.0, l: -0.3833, m: 3.238, s: 0.08985, sd3neg: 2.5, sd2neg: 2.7, sd1neg: 2.9, sd0: 3.2, sd1pos: 3.5, sd2pos: 3.9, sd3pos: 4.3),
    LmsPoint(x: 55.0, l: -0.3833, m: 4.348, s: 0.08800, sd3neg: 3.3, sd2neg: 3.6, sd1neg: 4.0, sd0: 4.3, sd1pos: 4.8, sd2pos: 5.2, sd3pos: 5.7),
    LmsPoint(x: 60.0, l: -0.3833, m: 5.626, s: 0.08650, sd3neg: 4.3, sd2neg: 4.7, sd1neg: 5.1, sd0: 5.6, sd1pos: 6.2, sd2pos: 6.7, sd3pos: 7.4),
    LmsPoint(x: 65.0, l: -0.3833, m: 7.009, s: 0.08550, sd3neg: 5.4, sd2neg: 5.9, sd1neg: 6.4, sd0: 7.0, sd1pos: 7.6, sd2pos: 8.3, sd3pos: 9.1),
    LmsPoint(x: 70.0, l: -0.3833, m: 8.239, s: 0.08510, sd3neg: 6.4, sd2neg: 6.9, sd1neg: 7.5, sd0: 8.2, sd1pos: 9.0, sd2pos: 9.8, sd3pos: 10.7),
    LmsPoint(x: 75.0, l: -0.3833, m: 9.247, s: 0.08540, sd3neg: 7.2, sd2neg: 7.8, sd1neg: 8.5, sd0: 9.2, sd1pos: 10.1, sd2pos: 11.0, sd3pos: 12.1),
    LmsPoint(x: 80.0, l: -0.3833, m: 10.165, s: 0.08640, sd3neg: 7.9, sd2neg: 8.6, sd1neg: 9.3, sd0: 10.2, sd1pos: 11.1, sd2pos: 12.2, sd3pos: 13.4),
    LmsPoint(x: 85.0, l: -0.3833, m: 11.205, s: 0.08810, sd3neg: 8.7, sd2neg: 9.4, sd1neg: 10.3, sd0: 11.2, sd1pos: 12.3, sd2pos: 13.5, sd3pos: 14.9),
    LmsPoint(x: 90.0, l: -0.3833, m: 12.378, s: 0.09060, sd3neg: 9.5, sd2neg: 10.3, sd1neg: 11.3, sd0: 12.4, sd1pos: 13.6, sd2pos: 15.0, sd3pos: 16.6),
    LmsPoint(x: 95.0, l: -0.3833, m: 13.666, s: 0.09370, sd3neg: 10.4, sd2neg: 11.3, sd1neg: 12.4, sd0: 13.7, sd1pos: 15.1, sd2pos: 16.7, sd3pos: 18.6),
    LmsPoint(x: 100.0, l: -0.3833, m: 15.071, s: 0.09730, sd3neg: 11.3, sd2neg: 12.4, sd1neg: 13.6, sd0: 15.1, sd1pos: 16.7, sd2pos: 18.6, sd3pos: 20.8),
    LmsPoint(x: 105.0, l: -0.3833, m: 16.608, s: 0.10130, sd3neg: 12.3, sd2neg: 13.5, sd1neg: 14.9, sd0: 16.6, sd1pos: 18.5, sd2pos: 20.8, sd3pos: 23.4),
    LmsPoint(x: 110.0, l: -0.3833, m: 18.291, s: 0.10560, sd3neg: 13.4, sd2neg: 14.8, sd1neg: 16.4, sd0: 18.3, sd1pos: 20.5, sd2pos: 23.2, sd3pos: 26.3),
    LmsPoint(x: 115.0, l: -0.3833, m: 20.128, s: 0.11020, sd3neg: 14.5, sd2neg: 16.1, sd1neg: 18.0, sd0: 20.1, sd1pos: 22.7, sd2pos: 25.8, sd3pos: 29.5),
    LmsPoint(x: 120.0, l: -0.3833, m: 22.127, s: 0.11500, sd3neg: 15.7, sd2neg: 17.5, sd1neg: 19.7, sd0: 22.1, sd1pos: 25.1, sd2pos: 28.7, sd3pos: 33.1),
  ];
}
