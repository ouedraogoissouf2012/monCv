import 'package:flutter/material.dart';

/// Palette centralisee. Les widgets utilisent d'abord le ColorScheme du theme;
/// ces tokens couvrent les statuts metier et les teintes decoratives partagees.
abstract final class AppColors {
  // Accessible semantic colors and their foregrounds (WCAG AA normal text).
  static const Color primary = Color(0xFF2563EB);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF1D4ED8);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF047857);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFF92400E);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD11D1D);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color info = Color(0xFF1D4ED8);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF60A5FA);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  // Business indicators.
  static const Color scoreGood = success;
  static const Color scoreMedium = warning;
  static const Color scorePoor = error;
  static const Color statusDraft = Color(0xFF64748B);
  static const Color statusSent = primary;
  static const Color statusInterview = Color(0xFF7C3AED);
  static const Color statusTechnicalTest = warning;
  static const Color statusOffer = success;
  static const Color statusRejected = error;
  static const Color statusArchived = Color(0xFF475569);

  // Brand and feature accents.
  static const Color brandBlue = Color(0xFF1847D6);
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueLight = Color(0xFF60A5FA);
  static const Color indigo = Color(0xFF6366F1);
  static const Color vibrantPrimary = Color(0xFF5B4BD8);
  static const Color vibrantSecondary = Color(0xFF764BA2);
  static const Color violet = Color(0xFF8B5CF6);
  // Violet clair (violet-400) : lisible sur fond sombre (statut "interview"
  // du theme Premium), contraste >= 4.5:1 verifie par test.
  static const Color violetLight = Color(0xFFA78BFA);
  static const Color violetMuted = Color(0xFF7864C8);
  static const Color pink = Color(0xFFEC4899);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealLight = Color(0xFF14B8A6);
  static const Color green = Color(0xFF10B981);
  static const Color greenStrong = Color(0xFF16A34A);
  static const Color orange = Color(0xFFEA580C);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberStrong = Color(0xFFD97706);
  static const Color yellowStrong = Color(0xFFCA8A04);

  // Neutral scale.
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color neutral950 = Color(0xFF0F1117);
  static const Color neutral900 = Color(0xFF111827);
  static const Color neutral850 = Color(0xFF1A1A18);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral750 = Color(0xFF1E3A5F);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral450 = Color(0xFF6B7280);
  static const Color neutral400 = Color(0xFF7A7A72);
  static const Color neutral350 = Color(0xFF94A3B8);
  static const Color neutral300 = Color(0xFF9CA3AF);
  static const Color neutral250 = Color(0xFFBBB9B2);
  static const Color neutral200 = Color(0xFFDDDBD4);
  static const Color neutral150 = Color(0xFFE2E8F0);
  static const Color neutral100 = Color(0xFFE5E7EB);
  static const Color neutral75 = Color(0xFFF1F5F9);
  static const Color neutral50 = Color(0xFFF8FAFC);

  // Surfaces and containers.
  static const Color warmBackground = Color(0xFFF5F3EE);
  static const Color warmSurface = Color(0xFFFAFAF8);
  static const Color coolBackground = neutral50;
  static const Color coolSurface = white;
  static const Color blueSurface = Color(0xFFEFF6FF);
  static const Color greenSurface = Color(0xFFF0FDF4);
  static const Color violetSurface = Color(0xFFF5F0FF);
  static const Color violetContainer = Color(0xFFEDE9FF);
  static const Color orangeSurface = Color(0xFFFFF7ED);
  static const Color yellowSurface = Color(0xFFFEFCE8);
  static const Color redSurface = Color(0xFFFEF2F2);
  static const Color publicSurface = Color(0xFFF3F6FA);
  static const Color sectionSurface = Color(0xFFF9FAFB);
  static const Color previewSurface = Color(0xFFF5F5F5);

  // Soft borders and feedback containers.
  static const Color blueBorder = Color(0xFFBFDBFE);
  static const Color greenBorder = Color(0xFFBBF7D0);
  static const Color orangeBorder = Color(0xFFFED7AA);
  static const Color yellowBorder = Color(0xFFFEF08A);
  static const Color redBorder = Color(0xFFFECACA);
  static const Color redStrong = Color(0xFFEF4444);
  // Rouge clair (red-400) : lisible sur les surfaces sombres du theme Premium
  // (score "faible"), contraste >= 4.5:1 verifie par test.
  static const Color redLight = Color(0xFFF87171);
  static const Color orangeText = Color(0xFFB45309);

  // Premium theme.
  static const Color premiumPrimary = Color(0xFFFFD700);
  static const Color premiumSecondary = Color(0xFFFFA500);
  static const Color premiumBackground = neutral950;
  static const Color premiumSurface = Color(0xFF1A1D2E);
  static const Color premiumContainer = Color(0xFF252840);
  static const Color premiumOnSurface = Color(0xFFE0E0E0);
  static const Color premiumOutline = Color(0x33FFD700);
  static const Color premiumOutlineSoft = Color(0x26FFD700);

  // Shadows.
  static const Color shadowSoft = Color(0x0A000000);
  static const Color shadowMedium = Color(0x12000000);
}
