
import 'package:fawateery/features/browse_codeforces/widgets/browse_codeforces_view_body.dart';
import 'package:flutter/material.dart';

class BrowseCodeforcesView extends StatelessWidget {
  const BrowseCodeforcesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Codeforces'),
      ),
      body: const BrowseCodeforcesViewBody(),
    );
  }
}