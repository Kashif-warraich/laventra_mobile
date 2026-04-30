import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Back arrow + title header used by every sub-screen (Event Detail,
/// Lavaggio Settings, profile sub-pages, etc). Optional trailing action.
class SubHeader extends StatelessWidget {
  final String       title;
  final VoidCallback? onBack;
  final Widget?      action;

  const SubHeader({super.key, required this.title, this.onBack, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: AppTokens.tp, size: 22),
            splashRadius: 22,
          ),
          Expanded(
            child: Text(title,
              style: const TextStyle(color: AppTokens.tp, fontSize: 17, fontWeight: FontWeight.w800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
