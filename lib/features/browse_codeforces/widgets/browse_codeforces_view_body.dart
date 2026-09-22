import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BrowseCodeforcesViewBody extends StatefulWidget {
  const BrowseCodeforcesViewBody({super.key});

  @override
  State<BrowseCodeforcesViewBody> createState() =>
      _BrowseCodeforcesViewBodyState();
}

class _BrowseCodeforcesViewBodyState extends State<BrowseCodeforcesViewBody> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..loadRequest(Uri.parse('https://codeforces.com/'));
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: WebViewWidget(controller: controller));
  }
}
