import 'package:flutter/material.dart';

class MoreMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MoreMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      // ZAMIANA: używamy child zamiast icon -> pełna kontrola nad wyglądem
      child: IconButton(
        onPressed: null, // ważne: onPressed null, bo klik obsługuje PopupMenuButton
        icon: const Icon(Icons.more_vert),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        style: ButtonStyle(
          // brak prostokątnego "podświetlenia" na hover/click
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          // okrągły hitbox (zamiast kwadratu)
          shape: WidgetStateProperty.all(const CircleBorder()),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),

      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edytuj')),
        PopupMenuItem(value: 'delete', child: Text('Usuń')),
      ],
    );
  }
}
