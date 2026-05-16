import 'package:flutter/material.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.onPressed, this.light = true});

  final VoidCallback? onPressed;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed ?? () {},
          icon: Icon(
            Icons.notifications_outlined,
            color: light ? Colors.white : null,
          ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
