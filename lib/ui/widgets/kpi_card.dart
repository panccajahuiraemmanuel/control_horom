import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

class KpiCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color colorValor;
  final IconData icono;

  const KpiCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.colorValor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 14, color: colorValor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colorValor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
