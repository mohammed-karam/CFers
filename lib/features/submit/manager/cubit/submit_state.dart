part of 'submit_cubit.dart';

/// Where the screen is in the hand-over to Codeforces.
sealed class SubmitState {
  const SubmitState();
}

/// The submit page is loading, or its form is being filled in.
final class SubmitOpening extends SubmitState {
  const SubmitOpening();
}

/// Codeforces wants a sign-in on the page; the student does it there, once.
final class SubmitNeedsLogin extends SubmitState {
  const SubmitNeedsLogin();
}

/// The form is ready, but the verdict cannot be watched without a handle.
final class SubmitNeedsHandle extends SubmitState {
  const SubmitNeedsHandle();
}

/// Prefilled and waiting for the student to press Submit.
final class SubmitReady extends SubmitState {
  const SubmitReady({this.language = ''});

  /// The compiler the page chose, e.g. `GNU G++17 7.3.0 (64 bit)`.
  final String language;
}

/// The page has been asked to press its own Submit button.
final class SubmitClicking extends SubmitState {
  const SubmitClicking();
}

/// Sent (or about to be): watching Codeforces for it to show up.
final class SubmitWaiting extends SubmitState {
  const SubmitWaiting({this.note});

  /// Shown when the page would not press Submit itself and the student has to
  /// tap it on the page — the verdict is being watched either way.
  final String? note;
}

/// Codeforces has the submission and is judging it.
final class SubmitJudging extends SubmitState {
  const SubmitJudging({required this.submission});

  final CfSubmission submission;
}

/// A verdict came back.
final class SubmitDone extends SubmitState {
  const SubmitDone({required this.submission});

  final CfSubmission submission;
}

/// Something needs the student's attention: the form would not fill, the page
/// went somewhere unexpected, or Codeforces stopped answering.
final class SubmitFailed extends SubmitState {
  const SubmitFailed({required this.message});

  final String message;
}
