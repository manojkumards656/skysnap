import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

class GuessTextField extends StatelessWidget {
  final TextEditingController controller;

  const GuessTextField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 1.0),
          ),
          child: TextField(
            controller: controller,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: const InputDecoration(
              hintText: 'Guess the cloud type...',
              hintStyle: TextStyle(color: Colors.white60),
              counterText: '',
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}
