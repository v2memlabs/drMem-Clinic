import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static audit: every `public.*` table created in migrations must enable RLS
/// before the migration chain ends (cumulative across files).
void main() {
  const skippedMigrationBasenames = {
    // Reference-only draft; superseded by draft_saas_schema_rls_v1.
    '20260521000000_draft_saas_schema.sql',
  };

  final createTable = RegExp(
    r'create\s+table(?:\s+if\s+not\s+exists)?\s+(?:public\.)?(\w+)\s*\(',
    caseSensitive: false,
  );
  final enableRls = RegExp(
    r'alter\s+table\s+(?:public\.)?(\w+)\s+enable\s+row\s+level\s+security',
    caseSensitive: false,
  );

  test('tenant tables in migrations enable row level security', () {
    final migrationsDir = Directory('supabase/migrations');
    expect(
      migrationsDir.existsSync(),
      isTrue,
      reason: 'supabase/migrations must exist',
    );

    final files = migrationsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .where((f) => !skippedMigrationBasenames.contains(_basename(f.path)))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final createdTables = <String>{};
    final rlsEnabledTables = <String>{};

    for (final file in files) {
      final content = file.readAsStringSync();
      for (final match in createTable.allMatches(content)) {
        createdTables.add(match.group(1)!);
      }
      for (final match in enableRls.allMatches(content)) {
        rlsEnabledTables.add(match.group(1)!);
      }
    }

    final missingRls = createdTables.difference(rlsEnabledTables).toList()
      ..sort();

    expect(
      missingRls,
      isEmpty,
      reason:
          'Tables created without RLS: ${missingRls.join(', ')}. '
          'Add `alter table public.<name> enable row level security`.',
    );
  });

  test('new remote migrations define at least one policy per created table', () {
    const remoteMigrationPrefixes = [
      '202607',
      '202608',
    ];
    final policyPattern = RegExp(
      r'create\s+policy\s+\w+\s+on\s+(?:public\.)?(\w+)',
      caseSensitive: false,
    );
    final createTableRemote = RegExp(
      r'create\s+table(?:\s+if\s+not\s+exists)?\s+(?:public\.)?(\w+)\s*\(',
      caseSensitive: false,
    );

    final migrationsDir = Directory('supabase/migrations');
    final files = migrationsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .where(
          (f) => remoteMigrationPrefixes.any(
            (prefix) => _basename(f.path).startsWith(prefix),
          ),
        )
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final createdTables = <String>{};
    final policyTables = <String>{};

    for (final file in files) {
      final content = file.readAsStringSync();
      for (final match in createTableRemote.allMatches(content)) {
        createdTables.add(match.group(1)!);
      }
      for (final match in policyPattern.allMatches(content)) {
        policyTables.add(match.group(1)!);
      }
    }

    if (createdTables.isEmpty) {
      return;
    }

    final missingPolicies = createdTables.difference(policyTables).toList()
      ..sort();

    expect(
      missingPolicies,
      isEmpty,
      reason:
          'Remote-era tables missing CREATE POLICY in same migration era: '
          '${missingPolicies.join(', ')}',
    );
  });
}

String _basename(String path) => path.split(Platform.pathSeparator).last;
