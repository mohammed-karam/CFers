import 'package:fawateery/features/browse_codeforces/views/browse_codeforces_view.dart';
import 'package:fawateery/features/code_compiler/views/code_compiler_view.dart';
import 'package:fawateery/features/online_friends/views/online_friends_view.dart';
import 'package:fawateery/features/user_details/views/user_details_view.dart';
import 'package:fawateery/features/user_rating/views/user_rating_view.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Codeforces Helper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      debugShowCheckedModeBanner: false,
      home: const BrowseCodeforcesView(),
    );
  }
}
