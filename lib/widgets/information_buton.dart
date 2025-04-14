import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

class InformationButon extends StatelessWidget {

  final String text;

  const InformationButon({super.key, required this.text});

  @override
  Widget build(BuildContext context) {

    final color = Theme.of(context).colorScheme;

    return Stack(
  children: [
    Positioned(
      bottom: 16,
      right: 16,
      child: BounceInDown(
        delay: Duration(microseconds: 1200),
        duration: const Duration(milliseconds: 700),
        child: IconButton(
          icon: Icon(Icons.info_outline, color: color.primary, size: 28),
          onPressed: () async {

            if (!context.mounted) return;

            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.info_outline, color: color.primary),
                    const SizedBox(width: 8),
                    Text(
                      "Información",
                      style: TextStyle(color: color.primary),
                    ),
                  ],
                ),
                content: Text(
  text
),


                actions: [
                  TextButton(
                    child: const Text("Entendido"),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  ],
);
  }
}