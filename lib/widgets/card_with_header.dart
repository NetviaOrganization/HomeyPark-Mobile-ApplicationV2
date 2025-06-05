import 'package:flutter/material.dart';

class CardWithHeader extends StatelessWidget {
  final String headerTextStr;
  final Widget body;

  const CardWithHeader(
      {super.key, required this.headerTextStr, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      shadowColor: theme.colorScheme.primary.withValues(alpha: (0.4 * 255).round().toDouble()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            margin: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: theme.colorScheme.onSurface.withValues(alpha: (0.1 * 255).round().toDouble()),
                ),
              ),
            ),
            child: Text(
              headerTextStr,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: body,
          ),
        ],
      ),
    );
  }
}
