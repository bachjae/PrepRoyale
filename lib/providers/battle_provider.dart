import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/battle_model.dart';
import '../models/question_model.dart';
import '../providers/auth_provider.dart';
import '../services/cloud_fn.dart';
import '../services/firebase_service.dart';

enum BattlePhase { idle, matchmaking, found, playing, finished, invited }

class BattleState {
  final BattlePhase phase;
  final BattleModel? battle;
  final QuestionModel? currentQuestion;
  final int? selectedAnswer;
  final int timeRemaining;
  final bool isSubmitting;
  final String? error;
  final int? myHealth;
  final int? opponentHealth;
  // Tracks how many questions I have personally answered (my question index)
  final int myAnswerCount;

  const BattleState({
    this.phase = BattlePhase.idle,
    this.battle,
    this.currentQuestion,
    this.selectedAnswer,
    this.timeRemaining = 30,
    this.isSubmitting = false,
    this.error,
    this.myHealth,
    this.opponentHealth,
    this.myAnswerCount = 0,
  });

  BattleState copyWith({
    BattlePhase? phase,
    BattleModel? battle,
    QuestionModel? currentQuestion,
    int? selectedAnswer,
    bool clearSelectedAnswer = false,
    int? timeRemaining,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    int? myHealth,
    int? opponentHealth,
    int? myAnswerCount,
  }) {
    return BattleState(
      phase: phase ?? this.phase,
      battle: battle ?? this.battle,
      currentQuestion: currentQuestion ?? this.currentQuestion,
      // Preserve selectedAnswer across RTDB updates; only clear when explicitly requested
      selectedAnswer: clearSelectedAnswer ? null : (selectedAnswer ?? this.selectedAnswer),
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      // Preserve error across state updates; only clear when explicitly requested
      error: clearError ? null : (error ?? this.error),
      myHealth: myHealth ?? this.myHealth,
      opponentHealth: opponentHealth ?? this.opponentHealth,
      myAnswerCount: myAnswerCount ?? this.myAnswerCount,
    );
  }
}

class BattleNotifier extends StateNotifier<BattleState> {
  final Ref _ref;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  StreamSubscription? _battleSubscription;
  StreamSubscription? _battleAssignmentSubscription;
  Timer? _timer;

  BattleNotifier(this._ref) : super(const BattleState());

  // Join matchmaking queue
  Future<void> joinMatchmaking({required String testType}) async {
    state = state.copyWith(phase: BattlePhase.matchmaking, clearError: true);

    try {
      // Use direct HTTP call to bypass Firebase callable SDK's App Check blocker
      final result = await callFn('joinMatchmaking', {'testType': testType});

      final battleId = (result as Map<String, dynamic>?)?['battleId'] as String?;
      if (battleId != null) {
        // We matched an opponent — subscribe to the battle directly
        _subscribeToBattle(battleId);
      } else {
        // We're in the queue — listen for server to assign us a battle when someone joins
        _listenForBattleAssignment();
      }
    } on CloudFnException catch (e) {
      state = state.copyWith(
        phase: BattlePhase.idle,
        error: _friendlyError(e.code, e.message, 'join matchmaking'),
      );
    } catch (e) {
      state = state.copyWith(
        phase: BattlePhase.idle,
        error:
            'Failed to join matchmaking. Please check your connection and try again.',
      );
    }
  }

  // Listen to /userBattles/{userId} for a battle ID written by the server
  // when an opponent joins and creates a battle for us.
  void _listenForBattleAssignment() {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    _battleAssignmentSubscription?.cancel();
    _battleAssignmentSubscription =
        _rtdb.ref('userBattles/$userId').onValue.listen((event) {
      if (event.snapshot.value == null) return;

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final battleId = data['battleId'] as String?;
      if (battleId != null) {
        _battleAssignmentSubscription?.cancel();
        _battleAssignmentSubscription = null;
        // Clean up the notification node so it doesn't re-trigger
        _rtdb.ref('userBattles/$userId').remove();
        _subscribeToBattle(battleId);
      }
    });
  }

  // Start a battle with a friend
  Future<void> startFriendBattle(
      {required String friendId, String testType = 'SAT'}) async {
    state = state.copyWith(phase: BattlePhase.matchmaking, clearError: true);

    try {
      final result = await callFn('createFriendBattle', {
        'friendId': friendId,
        'testType': testType,
      });

      final battleId = (result as Map<String, dynamic>?)?['battleId'] as String?;
      if (battleId != null) {
        _subscribeToBattle(battleId);
      }
    } on CloudFnException catch (e) {
      state = state.copyWith(
        phase: BattlePhase.idle,
        error: _friendlyError(e.code, e.message, 'start friend battle'),
      );
    } catch (e) {
      state = state.copyWith(
        phase: BattlePhase.idle,
        error:
            'Failed to start friend battle. Please check your connection and try again.',
      );
    }
  }

  // Subscribe to a specific battle as the invited player (from notification tap)
  void subscribeToInvitedBattle(String battleId) {
    if (state.phase != BattlePhase.idle) return; // already in a battle
    _subscribeToBattle(battleId);
    // phase will be set to BattlePhase.invited by _handleBattleUpdate
  }

  // Accept a friend battle invitation
  Future<void> acceptFriendBattle(String battleId) async {
    // Prevent double-accept (e.g., user taps Accept in both dialog and lobby)
    if (state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true);
    // Subscribe FIRST so the RTDB status change (waiting→inProgress) triggers phase: playing
    _subscribeToBattle(battleId);
    try {
      await callFn('acceptFriendBattle', {'battleId': battleId});
      // RTDB listener fires with status: inProgress → _handleBattleUpdate → phase: playing
    } on CloudFnException catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: _friendlyError(e.code, e.message, 'accept battle'),
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Failed to accept battle. Please try again.',
      );
    }
    // Note: isSubmitting is intentionally left true until RTDB fires with inProgress
    // and navigates to battle screen, to keep the Accept button disabled in lobby.
  }

  // Decline a friend battle invitation (invitee only)
  Future<void> declineFriendBattle(String battleId) async {
    try {
      await callFn('declineFriendBattle', {'battleId': battleId});
      leaveBattle();
    } on CloudFnException catch (e) {
      state = state.copyWith(error: _friendlyError(e.code, e.message, 'decline battle'));
    } catch (e) {
      state = state.copyWith(error: 'Failed to decline battle. Please try again.');
    }
  }

  // Cancel a pending friend battle invite (initiator only)
  Future<void> cancelFriendBattleInvite() async {
    if (state.battle == null) {
      leaveBattle();
      return;
    }
    try {
      await callFn('cancelFriendBattle', {'battleId': state.battle!.id});
    } catch (_) {
      // Ignore errors — clean up locally regardless
    }
    leaveBattle();
  }

  // Forfeit an active battle — opponent wins immediately
  Future<void> forfeitBattle() async {
    if (state.battle == null) return;
    try {
      await callFn('forfeitBattle', {'battleId': state.battle!.id});
      // RTDB listener fires with status: completed → phase: finished → battle screen navigates to results
    } on CloudFnException catch (e) {
      state = state.copyWith(error: _friendlyError(e.code, e.message, 'forfeit battle'));
    } catch (e) {
      state = state.copyWith(error: 'Failed to forfeit. Please try again.');
    }
  }

  // Subscribe to battle updates
  void _subscribeToBattle(String battleId) {
    _battleSubscription?.cancel();

    final battleRef = _rtdb.ref('battles/$battleId');
    _battleSubscription = battleRef.onValue.listen((event) {
      if (event.snapshot.value == null) {
        // Battle was deleted (friend declined, initiator cancelled, or server cleanup)
        if (state.phase != BattlePhase.idle && state.phase != BattlePhase.finished) {
          final wasWaiting = state.phase == BattlePhase.matchmaking;
          state = BattleState(
            error: wasWaiting ? 'Your friend declined the battle invitation.' : null,
          );
          _battleSubscription?.cancel();
          _battleSubscription = null;
        }
        return;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final battle = BattleModel.fromRealtimeDb(battleId, data);

      _handleBattleUpdate(battle);
    });
  }

  void _handleBattleUpdate(BattleModel battle) async {
    // Once finished, only accept a winnerId update if it was initially null.
    // This prevents a stale async _loadQuestion call from downgrading the
    // phase back to playing after we've already navigated to the results screen.
    if (state.phase == BattlePhase.finished) {
      if (battle.status == BattleStatus.completed &&
          battle.winnerId != null &&
          state.battle?.winnerId == null) {
        state = state.copyWith(battle: battle);
      }
      return;
    }

    final userId = _ref.read(currentUserIdProvider);

    // Declined: friend declined or initiator cancelled — notify initiator, silently reset invitee
    if (battle.status == BattleStatus.declined) {
      final isInitiator = battle.player1.odId == userId;
      state = BattleState(
        error: isInitiator ? 'Your friend declined the battle invitation.' : null,
      );
      _battleSubscription?.cancel();
      _battleSubscription = null;
      return;
    }

    // Waiting status: either a friend battle pending acceptance, or matchmaking waiting for opponent
    if (battle.status == BattleStatus.waiting) {
      if (battle.player2 != null) {
        // Friend battle: both players set but invite not yet accepted
        final isInvitee = battle.player2!.odId == userId;
        state = state.copyWith(
          phase: isInvitee ? BattlePhase.invited : BattlePhase.matchmaking,
          battle: battle,
        );
      } else {
        // Matchmaking: waiting for a second player
        state = state.copyWith(phase: BattlePhase.matchmaking, battle: battle);
      }
      return;
    }

    if (battle.status == BattleStatus.inProgress) {
      final isPlayer1 = battle.player1.odId == userId;
      final myPlayer = isPlayer1 ? battle.player1 : battle.player2;
      final opponent = isPlayer1 ? battle.player2 : battle.player1;

      // Per-player question index: how many answers I've personally submitted
      final myAnswerCount = myPlayer?.answers.length ?? 0;

      // All my questions answered — wait for battle to be completed by server
      if (myAnswerCount >= battle.questionIds.length) {
        state = state.copyWith(
          phase: BattlePhase.playing,
          battle: battle,
          myAnswerCount: myAnswerCount,
          myHealth: myPlayer?.health ?? 100,
          opponentHealth: opponent?.health ?? 100,
        );
        return;
      }

      // Load question for MY current index (only when my answer count changes
      // or when first loading)
      QuestionModel? question = state.currentQuestion;
      final needNewQuestion = question == null || myAnswerCount != state.myAnswerCount;

      if (needNewQuestion) {
        question = await _loadQuestion(battle.questionIds[myAnswerCount]);

        // Guard: phase may have changed to finished while awaiting _loadQuestion.
        // Don't overwrite the finished state with stale playing data.
        if (state.phase == BattlePhase.finished) return;

        _startQuestionTimer();
        // New question — clear selected answer and any lingering "accepting" flag
        state = state.copyWith(
          phase: BattlePhase.playing,
          battle: battle,
          currentQuestion: question,
          myAnswerCount: myAnswerCount,
          myHealth: myPlayer?.health ?? 100,
          opponentHealth: opponent?.health ?? 100,
          clearSelectedAnswer: true,
          isSubmitting: false,
        );
        return;
      }

      // Same question — just update health/battle without clearing selected answer
      state = state.copyWith(
        phase: BattlePhase.playing,
        battle: battle,
        currentQuestion: question,
        myAnswerCount: myAnswerCount,
        myHealth: myPlayer?.health ?? 100,
        opponentHealth: opponent?.health ?? 100,
      );
      return;
    }

    if (battle.status == BattleStatus.completed) {
      _timer?.cancel();

      // Note: Battle stats and XP are updated server-side in submitBattleAnswer
      // to prevent double-counting. Client only updates UI state here.

      state = state.copyWith(
        phase: BattlePhase.finished,
        battle: battle,
      );
    }
  }

  Future<QuestionModel?> _loadQuestion(String questionId) async {
    final firebaseService = _ref.read(firebaseServiceProvider);
    return await firebaseService.getQuestion(questionId);
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    state = state.copyWith(timeRemaining: 30);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining <= 1) {
        timer.cancel();
        // Auto-submit timeout only if no answer selected and still have questions
        if (state.selectedAnswer == null &&
            state.myAnswerCount < (state.battle?.questionIds.length ?? 20)) {
          submitAnswer(-1); // -1 indicates no answer (timeout)
        }
      } else {
        state = state.copyWith(timeRemaining: state.timeRemaining - 1);
      }
    });
  }

  // Select an answer
  void selectAnswer(int answer) {
    state = state.copyWith(selectedAnswer: answer);
  }

  // Submit answer
  // NOTE: Damage calculation happens server-side for security.
  // questionIndex is the player's personal answer count (per-player progression).
  Future<void> submitAnswer(int answer) async {
    if (state.battle == null || state.currentQuestion == null) return;
    if (state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true);

    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) return;

      // Use direct HTTP call — bypasses Firebase callable SDK's App Check blocker
      // Send the choice TEXT alongside the index so the server can compare by
      // content — the client shuffles choices for display, so the index seen
      // here (0-3) may not match the original unshuffled index stored in
      // Firestore. Text comparison survives the shuffle.
      final answerText = (answer >= 0 && answer < (state.currentQuestion!.choices.length))
          ? state.currentQuestion!.choices[answer]
          : null;
      await callFn('submitBattleAnswer', {
        'battleId': state.battle!.id,
        // Send MY personal answer index (not the global battle index)
        'questionIndex': state.myAnswerCount,
        'answer': answer,
        if (answerText != null) 'answerText': answerText,
      });
    } on CloudFnException catch (e) {
      state = state.copyWith(
          error: _friendlyError(e.code, e.message, 'submit answer'));
    } catch (e) {
      state =
          state.copyWith(error: 'Failed to submit answer. Please try again.');
    } finally {
      state = state.copyWith(isSubmitting: false, clearSelectedAnswer: true);
    }
  }

  // Leave battle/matchmaking
  void leaveBattle() {
    _timer?.cancel();
    _battleSubscription?.cancel();
    _battleAssignmentSubscription?.cancel();
    _battleAssignmentSubscription = null;
    state = const BattleState();
  }

  String _friendlyError(String code, String? message, String action) {
    switch (code) {
      case 'not_found':
      case 'not-found':
        return 'Game service unavailable. Please make sure the server is running.';
      case 'unauthenticated':
        return 'You must be signed in to $action.';
      case 'permission_denied':
      case 'permission-denied':
        return 'You do not have permission to $action.';
      case 'failed_precondition':
      case 'failed-precondition':
        return 'This battle is no longer available.';
      case 'unavailable':
        return 'Game service is temporarily unavailable. Please try again later.';
      case 'deadline_exceeded':
      case 'deadline-exceeded':
        return 'Request timed out. Please check your connection and try again.';
      default:
        return message ?? 'Failed to $action. Please try again.';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _battleSubscription?.cancel();
    _battleAssignmentSubscription?.cancel();
    super.dispose();
  }
}

final battleProvider =
    StateNotifierProvider<BattleNotifier, BattleState>((ref) {
  return BattleNotifier(ref);
});

/// Streams the pending battle invite for the current user from RTDB.
/// Returns null when there is no pending invite.
final pendingBattleInviteProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);

  return FirebaseDatabase.instance
      .ref('pendingBattleInvites/$userId')
      .onValue
      .map((event) {
        if (event.snapshot.value == null) return null;
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      });
});
