import 'package:flutter/material.dart';

class FamilyPage extends StatelessWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gia đình'),
      ),
      body: const Center(
        child: Text('Trang Quản lý Gia đình'),
      ),
    );
  }
}