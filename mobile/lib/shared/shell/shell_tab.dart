import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which of the four main pages is showing. The shell keeps one scaffold
/// and only this index changes.
class ShellTab extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) {
    if (index < 0 || index > 3) return;
    state = index;
  }
}

final shellTabProvider = NotifierProvider<ShellTab, int>(ShellTab.new);
