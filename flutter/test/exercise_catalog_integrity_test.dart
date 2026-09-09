import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Flutter and planner exercise catalogs stay identical and connected',
    () async {
      final appRaw = await rootBundle.loadString('assets/data/exercises.json');
      final plannerRaw = await File('../fitness-planner/data/exercises.json')
          .readAsString();
      final appRows = (jsonDecode(appRaw) as List).cast<Map<String, dynamic>>();
      final plannerRows = (jsonDecode(plannerRaw) as List)
          .cast<Map<String, dynamic>>();

      expect(appRows, hasLength(154));
      expect(jsonEncode(appRows), jsonEncode(plannerRows));

      final ids = appRows.map((row) => row['id'] as String).toSet();
      expect(
        ids,
        hasLength(appRows.length),
        reason: 'exercise ids must be unique',
      );
      expect(
        appRows.map((row) => row['movement_pattern']).toSet(),
        hasLength(15),
      );

      final dangling = <String>[];
      for (final row in appRows) {
        for (final field in const ['variations', 'alternatives_if_injured']) {
          for (final reference in (row[field] as List? ?? const [])) {
            if (!ids.contains(reference)) {
              dangling.add('${row['id']}.$field -> $reference');
            }
          }
        }
      }
      expect(dangling, isEmpty);
    },
  );
}
