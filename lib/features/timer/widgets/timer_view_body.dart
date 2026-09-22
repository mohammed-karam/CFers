import 'dart:async';
import 'dart:math';

import 'package:fawateery/features/timer/problem_difficulty_func.dart';
import 'package:fawateery/features/timer/widgets/show_stuck_dialog.dart';
import 'package:flutter/material.dart';

class TimerViewBody extends StatefulWidget {
  const TimerViewBody({super.key});

  @override
  State<TimerViewBody> createState() => _TimerViewBodyState();
}

class _TimerViewBodyState extends State<TimerViewBody> {
  int minutes = 1;
  int seconds = 0;
  int total = 1;
  int hint30 = 30;
  int hint60 = 60;
  bool hint30Shown = false;
  bool hint60Shown = false;
  bool isRunning = false;
  bool hintShown = false;

  late Timer? _timer;
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String formatTime(int num) {
    if (num < 10) {
      return '0$num';
    } else {
      return '$num';
    }
  }

  void startTimer() {
    isRunning = true;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (seconds == 0) {
          if (minutes == 0) {
            timer.cancel();
          } else {
            minutes--;
            seconds = 59;
          }
        } else {
          seconds--;
        }
        final elapsedSeconds = total * 60 - (minutes * 60 + seconds);

        if (elapsedSeconds == hint30 * 60 && !hint30Shown) {
          hint30Shown = true;
          showStuckDialog(30, context);
        }

        if (elapsedSeconds == hint60 * 60 && !hint60Shown) {
          hint60Shown = true;
          showStuckDialog(60, context);
        }
      });
    });
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _timer?.cancel();
    isRunning = false;
    super.dispose();
  }

  void clearTimer() {
    if (_timer != null) _timer?.cancel();
    setState(() {
      minutes = 0;
      seconds = 0;
      total = 0;
      isRunning = false;
    });
  }

  double calculateExpectedTime(int userRating, int problemRating) {
    const double baseTime = 30;

    final difference = problemRating - userRating;

    return baseTime * pow(2, difference / 300).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timer'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _ratingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Enter problem rating',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ),

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter problem rating';
                        }
                        if (int.tryParse(value)! < 800 ||
                            int.tryParse(value)! > 3500) {
                          return 'Enter a valid rating between 800 and 3500';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    ProblemDifficultyFunc(
                      userRating: 1500,
                      problemRating:
                          (int.tryParse(_ratingController.text) ?? 800),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a number';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }

                        if (minutes > 0 || seconds > 0) {
                          return 'Please Clear the timer before changing the time';
                        }
                        return null;
                      },

                      decoration: const InputDecoration(
                        labelText: 'Enter minutes',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ),
                      onFieldSubmitted: (value) {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                          setState(() {
                            minutes = int.tryParse(value!) ?? 0;
                            total = minutes;
                            seconds = 0;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Based on your rating, the expected time to solve this problem is: ${calculateExpectedTime(1500, int.tryParse(_ratingController.text) ?? 800).toStringAsFixed(2)} minutes',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 40),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: total == 0
                          ? 0
                          : (minutes * 60 + seconds) / (total * 60),
                      strokeWidth: 15,
                      color: Colors.red,
                    ),
                  ),

                  Text(
                    '${formatTime(minutes)}:${formatTime(seconds)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.red,
                      ),
                      foregroundColor: MaterialStateProperty.all<Color>(
                        Colors.white,
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                    ),
                    onPressed: () {
                      if (!isRunning) startTimer();
                      ;
                    },
                    child: const Text('Start Timer'),
                  ),

                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.yellow,
                      ),
                      foregroundColor: MaterialStateProperty.all<Color>(
                        Colors.black,
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                    ),
                    onPressed: () {
                      _timer?.cancel();
                      isRunning = false;
                    },
                    child: const Text('Stop Timer'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.blue,
                      ),
                      foregroundColor: MaterialStateProperty.all<Color>(
                        Colors.white,
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                      ),
                    ),
                    onPressed: () {
                      clearTimer();
                    },
                    child: const Text('Clear Timer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
