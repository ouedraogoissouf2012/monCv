import 'package:flutter/material.dart';

class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8082/api'; // Pour emulateur Android
  // static const String baseUrl = 'http://localhost:8082/api'; // Pour iOS/Web

  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String cvsEndpoint = '/cvs';
}

class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF3B82F6);
  static const Color accent = Color(0xFF60A5FA);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
}

class AppStrings {
  static const String appName = 'CV Mobile';
  static const String login = 'Connexion';
  static const String register = 'Inscription';
  static const String email = 'Email';
  static const String password = 'Mot de passe';
  static const String confirmPassword = 'Confirmer le mot de passe';
  static const String firstName = 'Prenom';
  static const String lastName = 'Nom';
  static const String forgotPassword = 'Mot de passe oublie ?';
  static const String noAccount = 'Pas encore de compte ?';
  static const String hasAccount = 'Deja un compte ?';
  static const String createAccount = 'Creer un compte';
  static const String myCvs = 'Mes CV';
  static const String createCv = 'Creer un CV';
  static const String editCv = 'Modifier le CV';
  static const String deleteCv = 'Supprimer le CV';
  static const String logout = 'Deconnexion';
  static const String profile = 'Profil';
  static const String settings = 'Parametres';
}
