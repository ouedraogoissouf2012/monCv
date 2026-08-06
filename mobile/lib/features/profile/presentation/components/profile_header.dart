import 'package:flutter/material.dart';

import '../../../../core/design_system/theme/app_theme_extensions.dart';
import '../profile_controller.dart';

/// Entete du profil : avatar a initiales, nom et email (issue #250, E4).
///
/// Purement presentationnelle — les initiales et le nom viennent du
/// [ProfileController] (E3). Le repli du nom absent est fourni par [fallbackName]
/// (localise par la vue).
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.controller,
    required this.fallbackName,
  });

  final ProfileController controller;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    return Center(
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primary.withValues(alpha: 0.3), width: 3),
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: primary.withValues(alpha: 0.12),
              child: Text(
                controller.initials,
                style: context.textStyles.headlineMedium?.copyWith(
                  color: primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            controller.fullName ?? fallbackName,
            style: context.textStyles.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            controller.email,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
