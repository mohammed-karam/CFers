import 'package:fawateery/core/theme/app_colors.dart';
import 'package:fawateery/core/widgets/custom_app_bar.dart';
import 'package:fawateery/features/shell/widgets/today_view_body.dart';
import 'package:flutter/material.dart';

class TodayView extends StatelessWidget {
  const TodayView({super.key, required this.onOpenTab});

  /// Switches to another shell tab (used by the "start learning" call to
  /// action on this screen).
  final void Function(int index) onOpenTab;

  static const List<String> _weekdays = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get _today {
    final now = DateTime.now();
    return '${_weekdays[now.weekday % 7]}, ${now.day} '
        '${_months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'Today', subtitle: _today),
      body: TodayViewBody(onOpenTab: onOpenTab),
    );
  }
}
