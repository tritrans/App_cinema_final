import 'package:flutter/material.dart';

class ApiDebugScreen extends StatelessWidget {
  const ApiDebugScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Debug'),
      ),
      body: const Center(
        child: Text('API Debug screen placeholder'),
      ),
    );
  }
}
