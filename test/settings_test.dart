import 'package:dartz/dartz.dart';
import 'package:fawateery/core/errors/failures.dart';
import 'package:fawateery/core/storage/app_settings.dart';
import 'package:fawateery/features/ai_tutor/views/ai_tutor_view.dart';
import 'package:fawateery/features/settings/views/settings_view.dart';
import 'package:fawateery/features/user_details/data/models/user_model.dart';
import 'package:fawateery/features/user_details/data/repo/user_info_repo.dart';
import 'package:fawateery/features/user_details/manager/cubit/user_info_cubit.dart';
import 'package:fawateery/features/user_details/widgets/user_details_view_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUserInfoRepo implements UserInfoRepo {
  _FakeUserInfoRepo({this.failure});

  Failure? failure;
  final List<String> requested = <String>[];

  @override
  Future<Either<Failure, UserModel>> getUserInfo(String handle) async {
    requested.add(handle);
    final failure = this.failure;
    if (failure != null) return Left(failure);
    return Right(
      UserModel(
        country: 'Egypt',
        lastName: '',
        lastOnlineTimeSeconds: 0,
        rating: 1400,
        friendOfCount: 0,
        titlePhoto: '',
        handle: handle,
        avatar: '',
        firstName: '',
        contribution: 0,
        organization: '',
        rank: 'pupil',
        maxRating: 1500,
        registrationTimeSeconds: 0,
        maxRank: 'specialist',
      ),
    );
  }
}

Future<void> _pumpProfile(WidgetTester tester, _FakeUserInfoRepo repo) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => UserInfoCubit(repo),
        child: const UserDetailsViewBody(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The screens scroll, so a control can sit below the fold; bring it on
/// screen before tapping or the tap lands outside the window.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettings.debugReset();
  });

  group('Settings', () {
    testWidgets('saves the key, model and handle to the device',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '  gsk_new_key  ');
      await tester.enterText(fields.at(1), 'custom-model');
      await tester.enterText(fields.at(2), '  Tolstoy  ');

      await _tap(tester, find.text('Save settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(AppSettings.instance.groqApiKey, 'gsk_new_key');
      expect(AppSettings.instance.groqModel, 'custom-model');
      expect(AppSettings.instance.codeforcesHandle, 'Tolstoy');
      expect(find.text('Settings saved on this device.'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('the profile screen opens the settings', (tester) async {
      await _pumpProfile(tester, _FakeUserInfoRepo());

      await _tap(tester, find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsView), findsOneWidget);
      expect(find.text('Your key, your model, your handle'), findsOneWidget);
    });
  });

  group('AI checker key gate', () {
    testWidgets('asks for a key the first time it is opened', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AiTutorView()));
      await tester.pumpAndSettle();

      expect(find.text('Add your Groq API key to start'), findsOneWidget);

      await _tap(tester, find.text('Paste my API key'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      final keyField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(keyField, 'gsk_from_prompt');
      await _tap(tester, find.text('Save'));
      await tester.pumpAndSettle();

      expect(AppSettings.instance.groqApiKey, 'gsk_from_prompt');
      expect(find.text('Add your Groq API key to start'), findsNothing);
    });

    testWidgets('submitting without a key opens the prompt, not the network',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AiTutorView()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'What is 2+2?');
      await tester.enterText(find.byType(TextField).at(1), '4');
      await _tap(tester, find.textContaining('Check my answer'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Groq API key'), findsOneWidget);
      expect(AppSettings.instance.hasGroqApiKey, isFalse);
    });
  });

  group('Profile handle', () {
    testWidgets('asks for a handle before it looks anything up',
        (tester) async {
      final repo = _FakeUserInfoRepo();
      await _pumpProfile(tester, repo);

      expect(find.text('Who are you?'), findsOneWidget);
      expect(find.text('Load my profile'), findsOneWidget);
      expect(repo.requested, isEmpty);

      await tester.enterText(find.byType(TextField), '  Tolstoy  ');
      await _tap(tester, find.text('Load my profile'));
      await tester.pumpAndSettle();

      expect(repo.requested, ['Tolstoy']);
      expect(AppSettings.instance.codeforcesHandle, 'Tolstoy');
      expect(find.text('Tolstoy'), findsWidgets);
    });

    testWidgets('uses the stored handle and offers a change', (tester) async {
      await AppSettings.instance.setCodeforcesHandle('Tolstoy');
      final repo = _FakeUserInfoRepo(
        failure: ServerFailure(errorMessage: 'Unknown handle'),
      );
      await _pumpProfile(tester, repo);

      expect(repo.requested, ['Tolstoy']);
      expect(find.text('Unknown handle'), findsOneWidget);
      expect(find.text('Change handle'), findsOneWidget);

      await _tap(tester, find.byTooltip('Change handle'));
      await tester.pumpAndSettle();

      final handleField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(handleField, 'TolstoyFan');
      await _tap(tester, find.text('Search'));
      await tester.pumpAndSettle();

      expect(repo.requested, ['Tolstoy', 'TolstoyFan']);
      expect(AppSettings.instance.codeforcesHandle, 'TolstoyFan');
    });
  });
}
