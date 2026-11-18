import 'package:flutter/material.dart';
import 'ui/home_shell.dart';

void main() {
  runApp(const MinaHorometrosApp());
}

class MinaHorometrosApp extends StatelessWidget {
  const MinaHorometrosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Horómetros',
      debugShowCheckedModeBanner: false,
      home: const HomeShell(),
    );
  }
}
