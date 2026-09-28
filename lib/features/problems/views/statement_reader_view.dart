import 'package:fawateery/core/theme/app_colors.dart';
import 'package:fawateery/core/widgets/custom_app_bar.dart';
import 'package:fawateery/features/problems/data/models/statement_model.dart';
import 'package:fawateery/features/problems/widgets/statement_body.dart';
import 'package:flutter/material.dart';

/// Comfortable full-screen reading of a statement, opened from the panel
/// above the editor when a student wants the whole problem at once.
class StatementReaderView extends StatelessWidget {
  const StatementReaderView({
    super.key,
    required this.title,
    required this.statement,
  });

  final String title;
  final ProblemStatement statement;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: title, subtitle: 'Statement'),
      body: SingleChildScrollView(
        child: StatementBody(statement: statement),
      ),
    );
  }
}
