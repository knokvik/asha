import 'package:drift/drift.dart';

/// Provides the drift migration strategy for AppDatabase.
///
/// Versioned migrations will be added in task 1.2 as tables are defined.
/// For now the strategy simply creates the schema from scratch on first run.
MigrationStrategy buildMigrationStrategy(GeneratedDatabase db) {
  return MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Per-version migration steps will be added here as the schema evolves.
    },
  );
}
