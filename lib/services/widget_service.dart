import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../config/router.dart';
import '../providers/auth_provider.dart';

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService(ref);
});

class WidgetService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String appGroupId = 'group.com.example.prep_royale';
  static const String iOSWidgetName = 'PrepRoyaleWidget';
  static const String androidWidgetName = 'SATACTWidgetProvider';

  static const String _prefKeyTipsCache = 'widget_tips_cache';
  static const String _prefKeyTipsDate = 'widget_tips_date';

  // Comprehensive fallback tips covering all categories
  static const List<Map<String, String>> _fallbackTipsData = [
    // Desmos tips
    {
      'tip':
          'Desmos: Type "y=mx+b" and use sliders for m and b to visualize slope and y-intercept instantly.',
      'category': 'desmos',
      'examType': 'SAT'
    },
    {
      'tip':
          'Desmos: Graph both sides of an equation separately to find intersection points visually.',
      'category': 'desmos',
      'examType': 'SAT'
    },
    {
      'tip':
          'Desmos: Use the table feature to find exact y-values for any x you input.',
      'category': 'desmos',
      'examType': 'SAT'
    },
    // Grammar tips
    {
      'tip':
          'Grammar: "Who" is for subjects (who did it), "whom" is for objects (to whom).',
      'category': 'grammar',
      'examType': 'Both'
    },
    {
      'tip':
          'Grammar: A comma splice (two sentences joined by just a comma) is ALWAYS wrong.',
      'category': 'grammar',
      'examType': 'Both'
    },
    {
      'tip':
          'Grammar: "Less" = uncountable (less water), "fewer" = countable (fewer bottles).',
      'category': 'grammar',
      'examType': 'Both'
    },
    {
      'tip':
          'Grammar: "Its" = possessive (the dog wagged its tail), "it\'s" = it is.',
      'category': 'grammar',
      'examType': 'Both'
    },
    {
      'tip':
          'Grammar: Parallel structure — items in a list must match in form.',
      'category': 'grammar',
      'examType': 'Both'
    },
    // Math tips
    {
      'tip': 'Math: Slope formula: m = (y2-y1)/(x2-x1). Rise over run.',
      'category': 'math',
      'examType': 'Both'
    },
    {
      'tip':
          'Math: Quadratic formula: x = (-b ± sqrt(b²-4ac)) / 2a. Memorize it!',
      'category': 'math',
      'examType': 'Both'
    },
    {
      'tip': 'Math: FOIL for binomials: (a+b)(c+d) = ac + ad + bc + bd.',
      'category': 'math',
      'examType': 'Both'
    },
    {
      'tip': 'Math: Area of a triangle = ½ × base × height.',
      'category': 'math',
      'examType': 'Both'
    },
    {
      'tip': 'Math: Distance = Rate × Time. Rearrange to find any variable.',
      'category': 'math',
      'examType': 'Both'
    },
    {
      'tip':
          'Math: Special triangles: 45-45-90 has sides 1:1:sqrt(2). 30-60-90 has sides 1:sqrt(3):2.',
      'category': 'math',
      'examType': 'Both'
    },
    // Science tips (ACT)
    {
      'tip':
          'Science (ACT): Read graphs and tables FIRST. Most answers come directly from the data.',
      'category': 'science',
      'examType': 'ACT'
    },
    {
      'tip':
          'Science (ACT): Pay close attention to axis labels and units — they\'re key to the question.',
      'category': 'science',
      'examType': 'ACT'
    },
    {
      'tip':
          'Science (ACT): Look for trends: as X increases, does Y increase, decrease, or stay the same?',
      'category': 'science',
      'examType': 'ACT'
    },
    // Reading tips
    {
      'tip':
          'Reading: Read the questions first to know what to look for in the passage.',
      'category': 'reading',
      'examType': 'Both'
    },
    {
      'tip':
          'Reading: Extreme words like "always", "never", "all" are usually wrong.',
      'category': 'reading',
      'examType': 'Both'
    },
    {
      'tip':
          'Reading: The correct answer is supported by TEXT EVIDENCE. Point to it!',
      'category': 'reading',
      'examType': 'Both'
    },
    {
      'tip':
          'Reading: Pay attention to transition words: however, therefore, in contrast.',
      'category': 'reading',
      'examType': 'Both'
    },
    // Strategy tips
    {
      'tip':
          'Strategy: Answer every question — there\'s no penalty for guessing.',
      'category': 'strategy',
      'examType': 'Both'
    },
    {
      'tip':
          'Strategy: Process of elimination is your best friend. Cross out wrong answers.',
      'category': 'strategy',
      'examType': 'Both'
    },
    {
      'tip':
          'Strategy: Skip hard questions and come back — don\'t lose easy points.',
      'category': 'strategy',
      'examType': 'Both'
    },
    // Time tips
    {
      'tip':
          'Time: SAT Reading: ~13 min per passage (5 passages, 65 min total).',
      'category': 'time',
      'examType': 'SAT'
    },
    {
      'tip': 'Time: ACT Math: ~1 min per question (60 questions, 60 min).',
      'category': 'time',
      'examType': 'ACT'
    },
    {
      'tip':
          'Time: Easy questions are worth the same as hard ones. Get the easy points first!',
      'category': 'time',
      'examType': 'Both'
    },
    {
      'tip':
          'Time: If a question takes more than 2 minutes, mark it and move on.',
      'category': 'time',
      'examType': 'Both'
    },
  ];

  // Simple string list for backward compatibility
  static final List<String> _fallbackTips =
      _fallbackTipsData.map((t) => t['tip']!).toList();

  WidgetService(this._ref);

  // Initialize widget and background updates
  Future<void> initialize() async {
    if (kIsWeb) return; // Home screen widgets are mobile-only

    // Initialize HomeWidget
    await HomeWidget.setAppGroupId(appGroupId);

    // Register callback for widget interactions (e.g., button taps)
    HomeWidget.widgetClicked.listen(_handleWidgetAction);

    // Initialize WorkManager for background updates
    await Workmanager().initialize(callbackDispatcher);

    // Register periodic task (every hour)
    await Workmanager().registerPeriodicTask(
      'widgetUpdate',
      'updateWidget',
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    // Initial update
    await updateWidget();
  }

  // Handle widget button clicks
  Future<void> _handleWidgetAction(Uri? uri) async {
    if (uri == null) return;

    debugPrint('Widget action received: $uri');

    // When the app is already open and the widget is tapped,
    // navigate to the study mode selector.
    try {
      final router = _ref.read(routerProvider);
      if (uri.host == 'study') {
        router.go('/study');
      } else {
        // Default: go to home screen
        router.go('/');
      }
    } catch (e) {
      // Router not ready yet (app is still initializing) — the system
      // deep link handler will open the app to the correct screen.
      debugPrint('Widget navigation deferred to system handler: $e');
    }
  }

  // Update widget data
  Future<void> updateWidget() async {
    if (kIsWeb) return;
    try {
      // Get hourly tip
      final tip = await _getHourlyTip();

      // Get user streak
      int dailyStreak = 0;
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          dailyStreak = userDoc.data()?['dailyStreak']?['count'] ?? 0;
        }
      }

      // Update widget data
      await HomeWidget.saveWidgetData<String>('tip', tip);
      await HomeWidget.saveWidgetData<int>('streak', dailyStreak);
      await HomeWidget.saveWidgetData<String>(
        'lastUpdated',
        DateTime.now().toIso8601String(),
      );

      // Trigger widget update on both platforms
      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
        androidName: androidWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  /// Update just the streak value in the widget (optimized for frequent updates)
  /// Call this after completing a study session to keep the widget in sync
  Future<void> updateStreakOnly(int dailyStreak) async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<int>('streak', dailyStreak);
      await HomeWidget.saveWidgetData<String>(
        'lastUpdated',
        DateTime.now().toIso8601String(),
      );

      // Trigger widget update on both platforms
      await HomeWidget.updateWidget(
        iOSName: iOSWidgetName,
        androidName: androidWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating widget streak: $e');
    }
  }

  /// Returns a tip selected by the current hour.
  ///
  /// Strategy:
  /// 1. If SharedPreferences contains tips cached today, return
  ///    `tips[currentHour % tips.length]` immediately.
  /// 2. Otherwise fetch all tips from the Firestore `widgetTips` collection,
  ///    cache them together with today's date, then return the hourly tip.
  /// 3. If Firestore fails, fall back to [_fallbackTips].
  Future<String> _getHourlyTip() async {
    final int currentHour = DateTime.now().hour;
    final String today = _todayDateString();

    // --- Step 1: try the cache ---
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedDate = prefs.getString(_prefKeyTipsDate);
      final String? cachedJson = prefs.getString(_prefKeyTipsCache);

      if (cachedDate == today && cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(cachedJson) as List<dynamic>;
        if (decoded.isNotEmpty) {
          final List<String> tips = decoded.map((e) => e as String).toList();
          return tips[currentHour % tips.length];
        }
      }
    } catch (_) {
      // If SharedPreferences fails, fall through to Firestore fetch.
    }

    // --- Step 2: fetch from Firestore ---
    try {
      final tipsSnapshot = await _firestore.collection('widgetTips').get();

      if (tipsSnapshot.docs.isNotEmpty) {
        final List<String> tips = tipsSnapshot.docs
            .map((doc) => doc.data()['tip'] as String)
            .toList();

        // Cache for the rest of today
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefKeyTipsCache, jsonEncode(tips));
          await prefs.setString(_prefKeyTipsDate, today);
        } catch (_) {
          // Caching failure is non-fatal; we already have the tips.
        }

        return tips[currentHour % tips.length];
      }
    } catch (_) {
      // Firestore fetch failed; fall through to fallback tips.
    }

    // --- Step 3: fallback ---
    return _fallbackTips[currentHour % _fallbackTips.length];
  }

  /// Returns today's date as an ISO-8601 date-only string (e.g. "2026-02-10").
  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Returns the "Tip of the Day" - a deterministic tip based on the current date.
  /// This ensures all users see the same tip on any given day.
  ///
  /// [examType] - Filter tips by exam type ('SAT', 'ACT', or null for all)
  /// [category] - Filter tips by category ('desmos', 'grammar', 'math', 'science', 'reading', 'strategy', 'time')
  Future<Map<String, String>> getTipOfTheDay({
    String? examType,
    String? category,
  }) async {
    // Try to get from Firestore
    try {
      var query = _firestore.collection('widgetTips').limit(500);

      // Note: Firestore doesn't support 'in' queries easily from client,
      // so we fetch all and filter client-side for simplicity
      final tipsSnapshot = await query.get();

      if (tipsSnapshot.docs.isNotEmpty) {
        List<Map<String, String>> tips = tipsSnapshot.docs
            .map((doc) => {
                  'tip': doc.data()['tip'] as String? ?? '',
                  'category': doc.data()['category'] as String? ?? 'strategy',
                  'examType': doc.data()['examType'] as String? ?? 'Both',
                })
            .where((t) {
          // Filter by examType if specified
          if (examType != null && examType != 'Both') {
            if (t['examType'] != examType && t['examType'] != 'Both') {
              return false;
            }
          }
          // Filter by category if specified
          if (category != null && t['category'] != category) {
            return false;
          }
          return true;
        }).toList();

        if (tips.isNotEmpty) {
          // Use day of year for deterministic selection
          final now = DateTime.now();
          final startOfYear = DateTime(now.year, 1, 1);
          final dayOfYear = now.difference(startOfYear).inDays;

          return tips[dayOfYear % tips.length];
        }
      }
    } catch (_) {
      // Fall through to fallback
    }

    // Fallback to local tips
    List<Map<String, String>> filteredFallback = _fallbackTipsData.where((t) {
      if (examType != null && examType != 'Both') {
        if (t['examType'] != examType && t['examType'] != 'Both') {
          return false;
        }
      }
      if (category != null && t['category'] != category) {
        return false;
      }
      return true;
    }).toList();

    if (filteredFallback.isEmpty) {
      filteredFallback = _fallbackTipsData;
    }

    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays;

    return filteredFallback[dayOfYear % filteredFallback.length];
  }

  /// Get all available tip categories
  static List<String> get categories => [
        'desmos',
        'grammar',
        'math',
        'science',
        'reading',
        'strategy',
        'time',
      ];

  /// Get human-readable category name
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'desmos':
        return 'Desmos Calculator';
      case 'grammar':
        return 'Grammar & Writing';
      case 'math':
        return 'Math Formulas';
      case 'science':
        return 'Science (ACT)';
      case 'reading':
        return 'Reading Strategies';
      case 'strategy':
        return 'Test Strategies';
      case 'time':
        return 'Time Management';
      default:
        return category;
    }
  }
}

// WorkManager callback — runs in an isolated background context without Riverpod
// or Firestore access, so it relies entirely on the SharedPreferences cache.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'updateWidget':
        try {
          final tip = await _getHourlyTipFromCache();

          await HomeWidget.saveWidgetData<String>('tip', tip);
          await HomeWidget.saveWidgetData<String>(
            'lastUpdated',
            DateTime.now().toIso8601String(),
          );
          await HomeWidget.updateWidget(
            iOSName: 'PrepRoyaleWidget',
            androidName: 'SATACTWidgetProvider',
          );
        } catch (e) {
          debugPrint('Background task error: $e');
        }
        break;
    }
    return true;
  });
}

/// Standalone helper used by [callbackDispatcher].
///
/// Reads the tips cache written by [WidgetService._getHourlyTip] and returns
/// the tip for the current hour, falling back to [WidgetService._fallbackTips]
/// when the cache is absent or stale.
Future<String> _getHourlyTipFromCache() async {
  const String prefKeyTipsCache = 'widget_tips_cache';
  const String prefKeyTipsDate = 'widget_tips_date';

  final int currentHour = DateTime.now().hour;
  final now = DateTime.now();
  final String today = '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';

  try {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedDate = prefs.getString(prefKeyTipsDate);
    final String? cachedJson = prefs.getString(prefKeyTipsCache);

    if (cachedDate == today && cachedJson != null && cachedJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(cachedJson) as List<dynamic>;
      if (decoded.isNotEmpty) {
        final List<String> tips = decoded.map((e) => e as String).toList();
        return tips[currentHour % tips.length];
      }
    }
  } catch (_) {
    // Fall through to hardcoded fallback.
  }

  // Use the same fallback list as WidgetService.
  return WidgetService
      ._fallbackTips[currentHour % WidgetService._fallbackTips.length];
}
