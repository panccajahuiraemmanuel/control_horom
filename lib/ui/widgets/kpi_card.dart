import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color colorValor;

  const KpiCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.colorValor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: colorValor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
