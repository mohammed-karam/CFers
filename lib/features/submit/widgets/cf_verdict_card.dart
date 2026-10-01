import 'dart:async';

import 'package:fawateery/core/storage/app_settings.dart';
import 'package:fawateery/core/theme/app_colors.dart';
import 'package:fawateery/features/problems/data/models/problem_model.dart';
import 'package:fawateery/features/submit/data/cf_submission.dart';
import 'package:fawateery/features/submit/data/cf_submissions_api.dart';
import 'package:fawateery/features/submit/data/cf_verdict_store.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The verdict of the student's last submission to this problem, waiting
/// above the Run button when they come back from the submit screen.
///
/// Renders nothing when they have never submitted here, so the workspace
/// keeps its shape for everyone else.
class CfVerdictCard extends StatefulWidget {
  const CfVerdictCard({super.key, required this.problem});

  final ProblemRef problem;

  @override
  State<CfVerdictCard> createState() => _CfVerdictCardState();
}

class _CfVerdictCardState extends State<CfVerdictCard> {
  static const Color _ok = Color(0xFF16A34A);
  static const Color _bad = Color(0xFFDC2626);

  final CfSubmissionsApi _api = CfSubmissionsApi();

  CfSubmission? _submission;
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _submission = _forThisProblem(CfVerdictStore.instance.read());
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  CfSubmission? _forThisProblem(CfSubmission? submission) =>
      submission != null && submission.problemCode == widget.problem.id
          ? submission
          : null;

  /// Keep watching only while the answer could still change: a verdict that
  /// is still being judged, or one so fresh that it may be a step behind.
  void _schedule() {
    final submission = _submission;
    if (submission == null) return;
    if (!(submission.isJudging || submission.isRecent)) return;
    _timer = Timer(const Duration(seconds: 4), _refresh);
  }

  Future<void> _refresh() async {
    if (_busy || !mounted) return;
    _busy = true;

    try {
      final handle = AppSettings.instance.codeforcesHandle;
      if (handle.isEmpty) return;

      final result = await _api.latestFor(handle);
      final latest = result.fold<CfSubmission?>((_) => null, (value) => value);
      final match = _forThisProblem(latest);
      if (!mounted || match == null) return;

      setState(() => _submission = match);
      await CfVerdictStore.instance.write(match);
      if (mounted) _schedule();
    } finally {
      _busy = false;
    }
  }

  Future<void> _openOnCodeforces() => launchUrl(
        Uri.parse(
          'https://codeforces.com/problemset/status/'
          '${AppSettings.instance.codeforcesHandle}',
        ),
        mode: LaunchMode.platformDefault,
      );

  @override
  Widget build(BuildContext context) {
    final submission = _submission;
    if (submission == null) return const SizedBox.shrink();

    final judging = submission.isJudging;
    final color = judging
        ? AppColors.navy
        : (submission.looksGood ? _ok : _bad);
    final handle = AppSettings.instance.codeforcesHandle;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (judging)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.navy,
              ),
            )
          else
            Icon(
              submission.looksGood
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              size: 15,
              color: color,
            ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  judging
                      ? 'Running on the judges…'
                      : submission.friendlyVerdict,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${submission.problemCode} · ${submission.language}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (handle.isNotEmpty)
            IconButton(
              tooltip: 'View on Codeforces',
              onPressed: _openOnCodeforces,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              color: AppColors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }
}
