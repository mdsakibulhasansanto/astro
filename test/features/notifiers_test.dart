import 'dart:async';

import 'package:astro_home/core/constants/furniture_catalog.dart';
import 'package:astro_home/core/network/app_exception.dart';
import 'package:astro_home/core/router/app_router.dart';
import 'package:astro_home/core/router/route_names.dart';
import 'package:astro_home/features/auth/model/app_user_model.dart';
import 'package:astro_home/features/auth/model/login_model.dart';
import 'package:astro_home/features/auth/model/sign_up_model.dart';
import 'package:astro_home/features/auth/repository/auth_repo.dart';
import 'package:astro_home/features/auth/riverpod/auth_state_notifier.dart';
import 'package:astro_home/features/onboarding/repository/onboarding_repo.dart';
import 'package:astro_home/features/onboarding/riverpod/onboarding_state_notifier.dart';
import 'package:astro_home/features/room_planner/model/furniture_model.dart';
import 'package:astro_home/features/room_planner/model/home_model.dart';
import 'package:astro_home/features/room_planner/model/layout_checks.dart';
import 'package:astro_home/features/room_planner/model/room_model.dart';
import 'package:astro_home/features/room_planner/repository/room_planner_repo.dart';
import 'package:astro_home/features/room_planner/riverpod/furniture_planner_state_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _user = AppUserModel(id: 'u1', email: 'a@b.com', name: 'Ana');

class _FakeAuthRepo implements AuthRepo {
  _FakeAuthRepo({this.saved, this.failLogin = false});

  final AppUserModel? saved;
  final bool failLogin;
  final changes = StreamController<AppUserModel?>.broadcast();

  @override
  AppUserModel? get currentUser => saved;

  @override
  Stream<AppUserModel?> authChanges() => changes.stream;

  @override
  Future<AppUserModel?> restoreSession() async => saved;

  @override
  Future<AppUserModel> login(LoginModel model) async {
    if (failLogin) throw const AppException('Invalid login credentials');
    return _user;
  }

  @override
  Future<SignUpResult> signUp(SignUpModel model) async => SignUpResult.confirmEmail;

  @override
  Future<void> logout() async {}

  final recovery = StreamController<void>.broadcast();
  String? sentResetTo;
  String? newPassword;

  @override
  Stream<void> passwordRecoveryEvents() => recovery.stream;

  @override
  Future<void> sendPasswordReset(String email) async => sentResetTo = email;

  @override
  Future<void> updatePassword(String password) async => newPassword = password;

  @override
  Future<void> signInWithGoogle() async =>
      throw const AppException('Google sign-in is not set up yet. Use email for now.');
}

class _FakePlannerRepo implements RoomPlannerRepo {
  List<FurnitureModel>? savedItems;
  Set<String>? savedRemoved;

  @override
  Future<RoomModel> fetchRoom(String roomId) async =>
      const RoomModel(id: 'r1', homeId: 'h1', roomName: 'Study', width: 10, height: 20);

  @override
  Future<List<FurnitureModel>> fetchFurniture(String roomId) async => const [
    FurnitureModel(
      id: 'f1',
      localKey: 'f1',
      roomId: 'r1',
      type: FurnitureType.desk,
      label: 'Desk',
      x: 0.1,
      y: 0.1,
      width: 0.4,
      height: 0.1,
    ),
  ];

  @override
  Future<List<FurnitureModel>> saveFurniture({
    required String roomId,
    required List<FurnitureModel> items,
    required Set<String> removedIds,
  }) async {
    savedItems = items;
    savedRemoved = removedIds;
    return [for (final i in items) i.copyWith(id: i.id ?? 'db-${i.localKey}')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();

  // Unused in these tests.
  @override
  Future<List<HomeModel>> fetchHomes(String userId) => throw UnimplementedError();
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('authRedirect', () {
    String? go(AuthStatus s, String loc, {bool onboarded = true}) =>
        authRedirect(s, loc, onboardingDone: onboarded);

    test('waits on splash until the session is known', () {
      expect(go(AuthStatus.initial, RoutePaths.astrology), RoutePaths.splash);
      expect(go(AuthStatus.initial, RoutePaths.splash), isNull);
      expect(go(AuthStatus.initial, RoutePaths.splash, onboarded: false), isNull);
    });

    test('first launch shows the intro before login', () {
      expect(
        go(AuthStatus.unauthenticated, RoutePaths.splash, onboarded: false),
        RoutePaths.onboarding,
      );
      expect(
        go(AuthStatus.unauthenticated, RoutePaths.login, onboarded: false),
        RoutePaths.onboarding,
      );
      expect(go(AuthStatus.unauthenticated, RoutePaths.onboarding, onboarded: false), isNull);
    });

    test('after the intro, signed-out users only reach login and sign-up', () {
      expect(go(AuthStatus.unauthenticated, RoutePaths.planner), RoutePaths.login);
      expect(go(AuthStatus.unauthenticated, RoutePaths.splash), RoutePaths.login);
      expect(go(AuthStatus.unauthenticated, RoutePaths.onboarding), RoutePaths.login);
      expect(go(AuthStatus.error, RoutePaths.login), isNull);
      expect(go(AuthStatus.loading, RoutePaths.signUp), isNull);
    });

    test('signed-in users skip the intro and auth screens', () {
      expect(go(AuthStatus.authenticated, RoutePaths.login), RoutePaths.dashboard);
      expect(
        go(AuthStatus.authenticated, RoutePaths.onboarding, onboarded: false),
        RoutePaths.dashboard,
      );
      expect(go(AuthStatus.authenticated, '/planner/room/x'), isNull);
    });
  });

  group('password reset', () {
    test('a reset link forces the new-password screen', () {
      String? go(String loc, {bool recovery = false}) => authRedirect(
        AuthStatus.authenticated,
        loc,
        onboardingDone: true,
        passwordRecovery: recovery,
      );
      expect(go(RoutePaths.dashboard, recovery: true), RoutePaths.resetPassword);
      expect(go(RoutePaths.resetPassword, recovery: true), isNull);
      expect(go(RoutePaths.resetPassword), RoutePaths.dashboard);
      expect(
        authRedirect(AuthStatus.unauthenticated, RoutePaths.forgotPassword, onboardingDone: true),
        isNull,
      );
    });

    test('recovery event signs in for reset, saving a password ends it', () async {
      final repo = _FakeAuthRepo(saved: _user);
      final n = AuthStateNotifier(repo);
      await _settle();
      expect(await n.sendPasswordReset('a@b.com'), isNull);
      expect(repo.sentResetTo, 'a@b.com');
      repo.recovery.add(null);
      await _settle();
      expect(n.state.passwordRecovery, isTrue);
      expect(n.state.isAuthenticated, isTrue);
      expect(await n.updatePassword('newpass1'), isNull);
      expect(repo.newPassword, 'newpass1');
      expect(n.state.passwordRecovery, isFalse);
      n.dispose();
    });
  });

  test('Google sign-in that is not set up shows a clear message', () async {
    final n = AuthStateNotifier(_FakeAuthRepo());
    await _settle();
    await n.signInWithGoogle();
    expect(n.state.status, AuthStatus.error);
    expect(n.state.message, contains('Google sign-in is not set up'));
    n.dispose();
  });

  group('OnboardingStateNotifier', () {
    test('starts from the saved flag and saves completion', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final n = OnboardingStateNotifier(OnboardingRepo(prefs));
      expect(n.state, isFalse);
      await n.complete();
      expect(n.state, isTrue);
      // A fresh launch reads the saved value.
      expect(OnboardingStateNotifier(OnboardingRepo(prefs)).state, isTrue);
    });
  });

  group('AuthStateNotifier', () {
    test('restores a saved session', () async {
      final n = AuthStateNotifier(_FakeAuthRepo(saved: _user));
      expect(n.state.status, AuthStatus.initial);
      await _settle();
      expect(n.state.status, AuthStatus.authenticated);
      expect(n.state.user, _user);
      n.dispose();
    });

    test('login success and failure', () async {
      final ok = AuthStateNotifier(_FakeAuthRepo());
      await _settle();
      expect(ok.state.status, AuthStatus.unauthenticated);
      await ok.login(const LoginModel(email: 'a@b.com', password: 'secret1'));
      expect(ok.state.isAuthenticated, isTrue);
      await ok.logout();
      expect(ok.state.status, AuthStatus.unauthenticated);
      ok.dispose();

      final bad = AuthStateNotifier(_FakeAuthRepo(failLogin: true));
      await _settle();
      await bad.login(const LoginModel(email: 'a@b.com', password: 'wrong'));
      expect(bad.state.status, AuthStatus.error);
      expect(bad.state.message, 'Invalid login credentials');
      bad.clearMessage();
      expect(bad.state.status, AuthStatus.unauthenticated);
      bad.dispose();
    });

    test('sign-up with email confirmation stays signed out with a note', () async {
      final n = AuthStateNotifier(_FakeAuthRepo());
      await _settle();
      final created = await n.signUp(
        const SignUpModel(name: 'Ana', email: 'a@b.com', password: 'secret1'),
      );
      expect(created, isTrue);
      expect(n.state.status, AuthStatus.unauthenticated);
      expect(n.state.message, contains('Check your email'));
      n.dispose();
    });
  });

  group('planner history, colours and collisions', () {
    test('undo and redo whole gestures and edits', () async {
      final n = FurniturePlannerStateNotifier(_FakePlannerRepo(), 'r1');
      await n.load();
      expect(n.state.canUndo, isFalse);

      // A drag made of many small moves undoes in one step.
      n.beginGesture();
      n.moveBy('f1', 0.1, 0);
      n.moveBy('f1', 0.1, 0);
      expect(n.state.items.first.x, closeTo(0.3, 1e-9));
      n.setColor('f1', '#7E9A7A');
      expect(n.state.items.first.color, '#7E9A7A');

      n.undo(); // colour
      expect(n.state.items.first.color, isNull);
      n.undo(); // drag
      expect(n.state.items.first.x, closeTo(0.1, 1e-9));
      expect(n.state.canUndo, isFalse);
      n.redo();
      expect(n.state.items.first.x, closeTo(0.3, 1e-9));
      expect(n.state.canRedo, isTrue);

      // Deleting a saved piece and undoing brings it back unremoved.
      n.delete('f1');
      expect(n.state.removedIds, {'f1'});
      n.undo();
      expect(n.state.removedIds, isEmpty);
      n.dispose();
    });

    test('detects overlapping furniture but ignores rugs', () async {
      final n = FurniturePlannerStateNotifier(_FakePlannerRepo(), 'r1');
      await n.load();
      n.addItem(FurnitureType.chair); // centred, away from the desk at (0.1, 0.1)
      expect(n.state.overlapping, isEmpty);
      final chair = n.state.selected!;
      n.beginGesture();
      n.moveBy(chair.localKey, 0.1 - chair.x, 0.1 - chair.y);
      expect(n.state.overlapping, {'f1', chair.localKey});
      n.addItem(FurnitureType.rug);
      n.moveBy(n.state.selectedKey!, -1, -1); // rug under the desk: fine
      expect(n.state.overlapping, {'f1', chair.localKey});
      n.dispose();
    });

    test('applying a design replaces the layout and is undoable', () async {
      final n = FurniturePlannerStateNotifier(_FakePlannerRepo(), 'r1');
      await n.load();
      const design = [
        FurnitureModel(
          localKey: 'd-0',
          roomId: 'r1',
          type: FurnitureType.bed,
          label: 'Bed',
          x: 0,
          y: 0,
          width: 0.5,
          height: 0.3,
          color: '#8B6B4A',
        ),
      ];
      n.applyLayout(design);
      expect(n.state.items.single.type, FurnitureType.bed);
      expect(n.state.items.single.id, isNull);
      expect(n.state.removedIds, {'f1'});
      n.undo();
      expect(n.state.items.single.id, 'f1');
      n.dispose();
    });

    test('overlappingKeys and insideRoom helpers', () {
      FurnitureModel box(String k, double x, double y) => FurnitureModel(
        localKey: k,
        roomId: 'r',
        type: FurnitureType.table,
        label: k,
        x: x,
        y: y,
        width: 0.2,
        height: 0.2,
      );
      expect(overlappingKeys([box('a', 0, 0), box('b', 0.19, 0.19)]), isEmpty); // tiny touch
      expect(overlappingKeys([box('a', 0, 0), box('b', 0.1, 0.1)]), {'a', 'b'});
      expect(insideRoom(box('a', 0.8, 0.8)), isTrue);
      expect(insideRoom(box('a', 0.9, 0.8)), isFalse);
    });
  });

  group('FurniturePlannerStateNotifier', () {
    test('add, move, rotate, delete and save', () async {
      final repo = _FakePlannerRepo();
      final n = FurniturePlannerStateNotifier(repo, 'r1');
      await n.load();
      expect(n.state.status, PlannerStatus.ready);
      expect(n.state.items, hasLength(1));

      // Moves are clamped inside the room.
      n.moveBy('f1', 5, -5);
      final desk = n.state.items.first;
      expect(desk.x, closeTo(0.6, 1e-9));
      expect(desk.y, 0);
      expect(n.state.isDirty, isTrue);

      // Rotating swaps the footprint (room is 10 wide, 20 deep).
      n.rotate('f1');
      final turned = n.state.items.first;
      expect(turned.rotation, 90);
      expect(turned.width * 10, closeTo(0.1 * 20, 1e-9));
      expect(turned.height * 20, closeTo(0.4 * 10, 1e-9));

      n.addItem(FurnitureType.bed);
      expect(n.state.items, hasLength(2));
      expect(n.state.selected?.type, FurnitureType.bed);
      // 5 ft bed in a 10 ft room is half the width.
      expect(n.state.selected!.width, closeTo(0.5, 1e-9));

      n.delete('f1');
      expect(n.state.removedIds, {'f1'});

      final error = await n.save();
      expect(error, isNull);
      expect(repo.savedRemoved, {'f1'});
      expect(repo.savedItems, hasLength(1));
      expect(n.state.isDirty, isFalse);
      expect(n.state.items.single.id, isNotNull);
      n.dispose();
    });
  });
}
