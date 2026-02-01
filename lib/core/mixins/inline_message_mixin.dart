import 'dart:async';
import 'package:flutter/material.dart';

/// Mixin to provide inline message functionality
/// Reduces code duplication across dialogs and forms
mixin InlineMessageMixin<T extends StatefulWidget> on State<T> {
  String? _inlineMessage;
  Color? _inlineMessageColor;
  Timer? _messageTimer;

  String? get inlineMessage => _inlineMessage;
  Color? get inlineMessageColor => _inlineMessageColor;

  /// Shows an inline message with optional background color and duration
  void showInlineMessage(
    String message, {
    Color? backgroundColor,
    Duration? duration,
  }) {
    final messageDuration = duration ?? const Duration(seconds: 5);
    _messageTimer?.cancel();
    setState(() {
      _inlineMessage = message;
      _inlineMessageColor = backgroundColor ?? Colors.black.withValues(alpha: 0.85);
    });
    _messageTimer = Timer(messageDuration, () {
      if (mounted) {
        setState(() {
          _inlineMessage = null;
        });
      }
    });
  }

  /// Clears the current inline message
  void clearInlineMessage() {
    _messageTimer?.cancel();
    if (mounted) {
      setState(() {
        _inlineMessage = null;
      });
    }
  }

  /// Builds the inline message widget if message exists
  Widget? buildInlineMessage() {
    if (_inlineMessage == null) return null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _inlineMessageColor ?? Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _inlineMessage!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }
}

