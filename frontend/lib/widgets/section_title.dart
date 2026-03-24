import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;

  const SectionTitle({
    super.key,
    required this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) Icon(icon, size: 20),
        if (icon != null) const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
