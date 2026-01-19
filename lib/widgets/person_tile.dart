import 'package:flutter/material.dart';
import '../models/user.dart';
import '../utils/colors.dart';

class PersonTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const PersonTile({required this.user, required this.onTap, Key? key}) : super(key: key);

  Color _colorFor(User u) {
    if (u.paidSessions <= 0) return UiColors.danger;
    if (u.paidSessions == 1) return UiColors.warning;
    return UiColors.ok;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(user);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
      ),
      title: Text(user.name),
      subtitle: Text('Opłacone treningi: ${user.paidSessions}'),
      onTap: onTap,
    );
  }
}
