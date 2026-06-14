import 'package:flutter/material.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key, this.promptId});
  final int? promptId;

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Editor')));
}
