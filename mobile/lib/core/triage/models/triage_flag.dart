/// Triage severity flag representing clinical priority:
/// [green] (routine care / reassurance),
/// [yellow] (monitor closely / primary care visit),
/// [red] (urgent referral / emergency care).
enum TriageFlag implements Comparable<TriageFlag> {
  green('GREEN', 0),
  yellow('YELLOW', 1),
  red('RED', 2);

  final String label;
  final int severity;

  const TriageFlag(this.label, this.severity);

  bool operator >(TriageFlag other) => severity > other.severity;
  bool operator >=(TriageFlag other) => severity >= other.severity;
  bool operator <(TriageFlag other) => severity < other.severity;
  bool operator <=(TriageFlag other) => severity <= other.severity;

  @override
  int compareTo(TriageFlag other) => severity.compareTo(other.severity);

  /// Escalate severity by one level, capping at [red].
  /// Requirements: 8.4 (Missing required fields escalate severity by one level).
  TriageFlag escalate() {
    switch (this) {
      case TriageFlag.green:
        return TriageFlag.yellow;
      case TriageFlag.yellow:
      case TriageFlag.red:
        return TriageFlag.red;
    }
  }

  String toUpper() => label;

  static TriageFlag fromString(String? value) {
    if (value == null) return TriageFlag.green;
    switch (value.trim().toUpperCase()) {
      case 'RED':
        return TriageFlag.red;
      case 'YELLOW':
        return TriageFlag.yellow;
      case 'GREEN':
      default:
        return TriageFlag.green;
    }
  }
}
