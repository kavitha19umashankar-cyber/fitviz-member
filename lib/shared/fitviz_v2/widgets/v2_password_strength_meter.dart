import 'package:flutter/material.dart';
import '../theme/fitviz_v2_colors.dart';

enum V2PasswordStrength { weak, fair, good, strong }

V2PasswordStrength v2ScorePassword(String value) {
  var score = 0;
  if (value.length >= 8) score++;
  if (RegExp(r'[0-9]').hasMatch(value)) score++;
  if (RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) score++;
  if (RegExp(r'[a-z]').hasMatch(value) && RegExp(r'[A-Z]').hasMatch(value)) score++;
  if (score <= 1) return V2PasswordStrength.weak;
  if (score == 2) return V2PasswordStrength.fair;
  if (score == 3) return V2PasswordStrength.good;
  return V2PasswordStrength.strong;
}

/// 3 thin pill segments filling left-to-right in accent, paired with a hint.
class V2PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const V2PasswordStrengthMeter({super.key, required this.password});

  int _filledSegments(V2PasswordStrength s) {
    switch (s) {
      case V2PasswordStrength.weak:
        return password.isEmpty ? 0 : 1;
      case V2PasswordStrength.fair:
        return 1;
      case V2PasswordStrength.good:
        return 2;
      case V2PasswordStrength.strong:
        return 3;
    }
  }

  String _hint(V2PasswordStrength s) {
    switch (s) {
      case V2PasswordStrength.weak:
        return 'Weak — use at least 8 characters.';
      case V2PasswordStrength.fair:
        return 'Fair — add a number or symbol.';
      case V2PasswordStrength.good:
        return 'Good — add a symbol or number to make it strong.';
      case V2PasswordStrength.strong:
        return 'Strong password.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = v2ScorePassword(password);
    final filled = _filledSegments(strength);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
                height: 3,
                decoration: BoxDecoration(
                  color: i < filled ? FitVizV2Colors.accent : FitVizV2Colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          _hint(strength),
          style: const TextStyle(color: FitVizV2Colors.inkDim, fontSize: 11),
        ),
      ],
    );
  }
}
