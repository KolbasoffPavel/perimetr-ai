import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Смахивание для удаления с тактильным откликом и снекбаром «Отменить» —
/// используется для позиций сметы, прайса, помещений и сообщений чата,
/// чтобы удаление больше не было необратимым одним случайным тапом.
class SwipeToDelete extends StatelessWidget {
final Object itemKey;
final Widget child;
final String confirmLabel;
final VoidCallback onDelete;
final VoidCallback onUndo;
const SwipeToDelete({
super.key,
required this.itemKey,
required this.child,
required this.confirmLabel,
required this.onDelete,
required this.onUndo,
});

@override
Widget build(BuildContext context) {
return Dismissible(
key: ValueKey(itemKey),
direction: DismissDirection.endToStart,
background: Container(
alignment: Alignment.centerRight,
padding: const EdgeInsets.symmetric(horizontal: 20),
margin: const EdgeInsets.only(bottom: 0),
decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(14)),
child: const Icon(Icons.delete_outline, color: Colors.white),
),
onDismissed: (_) {
HapticFeedback.mediumImpact();
onDelete();
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(confirmLabel),
action: SnackBarAction(label: 'Отменить', onPressed: onUndo),
duration: const Duration(seconds: 4),
),
);
},
child: child,
);
}
}
