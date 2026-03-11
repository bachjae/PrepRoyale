import 'package:mocktail/mocktail.dart';
import 'package:prep_royale/services/firebase_service.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

/// Fallback classes for mocktail's registerFallbackValue
class FakeLevelUpResult extends Fake implements LevelUpResult {}

class FakeStreakUpdateResult extends Fake implements StreakUpdateResult {}
