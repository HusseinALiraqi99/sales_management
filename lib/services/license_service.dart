import 'package:sales_management/database/database_helper.dart';

class LicenseService {
  static const String activationCode = 'SALE-2026-PRO-7X9K';

  static const int trialDays = 14;

  // ============================================================
  // تهيئة الترخيص
  // ============================================================

  static Future<void> initialize() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'license',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    // أول تشغيل
    if (result.isEmpty) {
      await db.insert('license', {
        'id': 1,
        'trialStart': DateTime.now().toIso8601String(),
        'isActivated': 0,
      });
    }
  }

  // ============================================================
  // هل البرنامج مفعل؟
  // ============================================================

  static Future<bool> isActivated() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'license',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) {
      return false;
    }

    return result.first['isActivated'] == 1;
  }

  // ============================================================
  // هل ما زالت فترة التجربة فعالة؟
  // ============================================================

  static Future<bool> isTrialActive() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'license',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) {
      return true;
    }

    if (result.first['isActivated'] == 1) {
      return true;
    }

    final trialStartString =
        result.first['trialStart']?.toString();

    if (trialStartString == null) {
      return true;
    }

    final trialStart = DateTime.tryParse(
      trialStartString,
    );

    if (trialStart == null) {
      return true;
    }

    final now = DateTime.now();

    final difference = now.difference(trialStart).inDays;

    return difference < trialDays;
  }

  // ============================================================
  // تفعيل البرنامج
  // ============================================================

  static Future<bool> activate(String code) async {
    if (code.trim() != activationCode) {
      return false;
    }

    final db = await DatabaseHelper.instance.database;

    await db.update(
      'license',
      {
        'isActivated': 1,
        'activatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    return true;
  }

  // ============================================================
  // هل يسمح البرنامج بالدخول؟
  // ============================================================

  static Future<bool> canUseProgram() async {
    if (await isActivated()) {
      return true;
    }

    return await isTrialActive();
  }
  static Future<int> getTrialDaysRemaining() async {
  final db =
      await DatabaseHelper.instance.database;

  final result = await db.query(
    'license',
    where: 'id = ?',
    whereArgs: [1],
    limit: 1,
  );

  if (result.isEmpty) {
    return trialDays;
  }

  if (result.first['isActivated'] == 1) {
    return 0;
  }

  final trialStartString =
      result.first['trialStart']?.toString();

  if (trialStartString == null) {
    return trialDays;
  }

  final trialStart =
      DateTime.tryParse(trialStartString);

  if (trialStart == null) {
    return trialDays;
  }

  final now = DateTime.now();

  final elapsedDays =
      now.difference(trialStart).inDays;

  final remainingDays =
      trialDays - elapsedDays;

  if (remainingDays < 0) {
    return 0;
  }

  return remainingDays;
}
}