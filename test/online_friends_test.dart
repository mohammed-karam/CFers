import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/features/online_friends/data/models/friend_info.dart';
import 'package:fawateery/features/online_friends/data/models/online_friends_model.dart';
import 'package:fawateery/features/online_friends/data/repo/online_friends_repo.dart';
import 'package:fawateery/features/online_friends/manager/online_friends_cubit/online_friends_cubit.dart';
import 'package:fawateery/features/online_friends/views/online_friends_view.dart';
import 'package:fawateery/features/online_friends/widgets/online_friends_view_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory repo: no test ever talks to Codeforces.
class _FakeRepo implements OnlineFriendsRepo {
  _FakeRepo({
    this.handles = const <String>[],
    this.info = const <String, FriendInfo>{},
    this.failFriends = false,
    this.failInfo = false,
  });

  List<String> handles;
  Map<String, FriendInfo> info;
  bool failFriends;
  bool failInfo;

  /// When set, [getOnlineFriends] hangs until the test opens the gate.
  Completer<void>? friendsGate;

  int friendsCalls = 0;
  int infoCalls = 0;
  List<List<String>> requestedInfo = <List<String>>[];

  @override
  Future<Either<Failure, OnlineFriendsModel>> getOnlineFriends() async {
    friendsCalls += 1;
    final gate = friendsGate;
    if (gate != null && !gate.isCompleted) await gate.future;
    if (failFriends) {
      return Left(ServerFailure(errorMessage: 'Codeforces is unreachable'));
    }
    return Right(
      OnlineFriendsModel(status: 'OK', result: List<String>.of(handles)),
    );
  }

  @override
  Future<Either<Failure, Map<String, FriendInfo>>> getFriendsInfo(
    List<String> handles,
  ) async {
    infoCalls += 1;
    requestedInfo.add(List<String>.of(handles));
    if (failInfo) {
      return Left(ServerFailure(errorMessage: 'Ratings are unavailable'));
    }
    return Right(Map<String, FriendInfo>.of(info));
  }
}

Future<void> _pumpView(WidgetTester tester, OnlineFriendsCubit cubit) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  addTearDown(cubit.close);

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        // Reduced motion keeps the pulsing online dot steady, so the tests
        // can settle without an endless pulse animation running.
        data: const MediaQueryData(disableAnimations: true),
        child: OnlineFriendsView(cubit: cubit),
      ),
    ),
  );
}

const _tanner = FriendInfo(
  handle: 'tanner',
  rating: 1421,
  maxRating: 1560,
  rank: 'specialist',
  titlePhoto: 'https://codeforces.com/uploads/user/avatar/tanner.jpg',
);
const _peter = FriendInfo(
  handle: 'peter',
  rating: 1103,
  maxRating: 1180,
  rank: 'newbie',
);
const _petra = FriendInfo(
  handle: 'petra',
  rating: 1642,
  maxRating: 1701,
  rank: 'expert',
);

void main() {
  group('FriendInfo', () {
    test('reads rating, rank and photo from a user.info entry', () {
      final info = FriendInfo.fromJson(const {
        'handle': 'tanner',
        'rating': 1421,
        'maxRating': 1560,
        'rank': 'specialist',
        'titlePhoto': 'https://codeforces.com/avatar.jpg',
      });

      expect(info.handle, 'tanner');
      expect(info.rating, 1421);
      expect(info.maxRating, 1560);
      expect(info.rankLabel, 'Specialist');
      expect(info.titlePhoto, 'https://codeforces.com/avatar.jpg');
      expect(info.isRated, isTrue);
    });

    test('leaves the rating out for a player who never competed', () {
      final info = FriendInfo.fromJson(const {'handle': 'newbieGuy'});

      expect(info.handle, 'newbieGuy');
      expect(info.rating, isNull);
      expect(info.maxRating, isNull);
      expect(info.rankLabel, '');
      expect(info.isRated, isFalse);
    });

    test('capitalises multi word ranks', () {
      const info = FriendInfo(
        handle: 'cm',
        rating: 1950,
        rank: 'candidate master',
      );
      expect(info.rankLabel, 'Candidate Master');
    });
  });

  group('filterOnlineFriends', () {
    test('matches part of a handle without caring about case', () {
      final visible = filterOnlineFriends(
        const ['tanner', 'peter', 'petra'],
        'PET',
      );
      expect(visible, ['peter', 'petra']);
    });

    test('a blank query keeps every handle in order', () {
      final visible = filterOnlineFriends(const ['b', 'a'], '   ');
      expect(visible, ['b', 'a']);
    });
  });

  group('OnlineFriendsCubit', () {
    test('loads the handles, then merges the public ratings', () async {
      final repo = _FakeRepo(
        handles: const ['tanner', 'peter'],
        info: const {'tanner': _tanner, 'peter': _peter},
      );
      final cubit = OnlineFriendsCubit(repo);

      await cubit.getOnlineFriends();

      final state = cubit.state;
      expect(state, isA<OnlineFriendsSuccess>());
      final success = state as OnlineFriendsSuccess;
      expect(success.onlineFriendsModel.result, ['tanner', 'peter']);
      expect(success.friendInfo?['tanner']?.rating, 1421);
      expect(success.friendInfo?['peter']?.rankLabel, 'Newbie');
      expect(repo.friendsCalls, 1);
      expect(repo.infoCalls, 1);
      expect(repo.requestedInfo.single, ['tanner', 'peter']);

      await cubit.close();
    });

    test('keeps the list when the ratings lookup fails', () async {
      final repo = _FakeRepo(handles: const ['tanner'], failInfo: true);
      final cubit = OnlineFriendsCubit(repo);

      await cubit.getOnlineFriends();

      final success = cubit.state as OnlineFriendsSuccess;
      expect(success.onlineFriendsModel.result, ['tanner']);
      expect(success.friendInfo, isNotNull);
      expect(success.friendInfo, isEmpty);

      await cubit.close();
    });

    test('surfaces a failure when the friends call itself fails', () async {
      final repo = _FakeRepo(handles: const ['tanner'], failFriends: true);
      final cubit = OnlineFriendsCubit(repo);

      await cubit.getOnlineFriends();

      expect(cubit.state, isA<OnlineFriendsFailure>());
      expect(
        (cubit.state as OnlineFriendsFailure).errorMessage,
        'Codeforces is unreachable',
      );
      expect(repo.infoCalls, 0);

      await cubit.close();
    });
  });

  group('OnlineFriendsView', () {
    testWidgets(
      'walks from the branded loading state into cards with ratings',
      (tester) async {
        final repo = _FakeRepo(
          handles: const ['tanner', 'peter'],
          info: const {'tanner': _tanner, 'peter': _peter},
        );
        repo.friendsGate = Completer<void>();
        final cubit = OnlineFriendsCubit(repo);
        await _pumpView(tester, cubit);

        await tester.pump();
        expect(find.text('Checking who is online...'), findsOneWidget);
        expect(find.text('Finding your online friends'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('tanner'), findsNothing);

        repo.friendsGate!.complete();
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('tanner'), findsOneWidget);
        expect(find.text('peter'), findsOneWidget);
        expect(find.text('2 online now'), findsOneWidget);

        // Rating badge, coloured by the Codeforces band.
        final badge = find.text('Specialist 1421');
        expect(badge, findsOneWidget);
        expect(
          tester.widget<Text>(badge).style?.color,
          const Color(0xFF03A89E),
        );
        expect(find.text('Newbie 1103'), findsOneWidget);

        // Initial letter avatar stands in for the photo that failed to load.
        expect(find.text('T'), findsOneWidget);
        expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));

        expect(repo.friendsCalls, 1);
        expect(repo.infoCalls, 1);
      },
    );

    testWidgets('renders the empty state when nobody is online',
        (tester) async {
      final cubit = OnlineFriendsCubit(_FakeRepo());
      await _pumpView(tester, cubit);
      await tester.pumpAndSettle();

      expect(find.text('No friends online right now'), findsOneWidget);
      expect(find.byIcon(Icons.group_off_rounded), findsOneWidget);
      expect(
        find.textContaining('Friends appear here the moment'),
        findsOneWidget,
      );
      expect(find.text('0 online now'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows the retry state and re-fetches on Try again',
        (tester) async {
      final repo = _FakeRepo(
        handles: const ['tanner'],
        info: const {'tanner': _tanner},
        failFriends: true,
      );
      final cubit = OnlineFriendsCubit(repo);
      await _pumpView(tester, cubit);
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load your friends"), findsOneWidget);
      expect(find.text('Codeforces is unreachable'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(repo.friendsCalls, 1);

      repo.failFriends = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('tanner'), findsOneWidget);
      expect(find.text('Specialist 1421'), findsOneWidget);
      expect(find.text('1 online now'), findsOneWidget);
      expect(repo.friendsCalls, 2);
    });

    testWidgets('search narrows the list and the live count',
        (tester) async {
      final repo = _FakeRepo(
        handles: const ['tanner', 'peter', 'petra'],
        info: const {'tanner': _tanner, 'peter': _peter, 'petra': _petra},
      );
      final cubit = OnlineFriendsCubit(repo);
      await _pumpView(tester, cubit);
      await tester.pumpAndSettle();

      expect(find.text('3 online now'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'PET');
      await tester.pump();

      expect(find.text('peter'), findsOneWidget);
      expect(find.text('petra'), findsOneWidget);
      expect(find.text('tanner'), findsNothing);
      expect(find.text('2 of 3 friends'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();

      expect(find.text('No matching friends'), findsOneWidget);
      expect(find.textContaining('No online friend matches'), findsOneWidget);
      expect(find.text('0 of 3 friends'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();

      expect(find.text('3 online now'), findsOneWidget);
      expect(find.text('tanner'), findsOneWidget);

      FocusScope.of(tester.element(find.byType(TextField))).unfocus();
      await tester.pump();
    });

    testWidgets('the app bar refresh action reloads the list',
        (tester) async {
      final repo = _FakeRepo(
        handles: const ['tanner'],
        info: const {'tanner': _tanner},
      );
      final cubit = OnlineFriendsCubit(repo);
      await _pumpView(tester, cubit);
      await tester.pumpAndSettle();

      expect(find.text('Online Codeforces Friends'), findsOneWidget);
      expect(repo.friendsCalls, 1);

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(repo.friendsCalls, 2);
      expect(repo.infoCalls, 2);
      expect(find.text('tanner'), findsOneWidget);
    });

    testWidgets('pulling the list down refreshes it', (tester) async {
      final repo = _FakeRepo(
        handles: const ['tanner', 'peter'],
        info: const {'tanner': _tanner, 'peter': _peter},
      );
      final cubit = OnlineFriendsCubit(repo);
      await _pumpView(tester, cubit);
      await tester.pumpAndSettle();

      expect(repo.friendsCalls, 1);

      await tester.drag(find.byType(ListView), const Offset(0, 320));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repo.friendsCalls, 2);
      expect(find.text('tanner'), findsOneWidget);
    });
  });
}
