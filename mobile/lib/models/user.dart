class User {
  final int id;
  final String email;
  final String? nom;
  final String? prenom;
  final String role;

  User({
    required this.id,
    required this.email,
    this.nom,
    this.prenom,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      nom: json['nom'],
      prenom: json['prenom'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'role': role,
    };
  }

  String get fullName {
    if (prenom != null && nom != null) {
      return '$prenom $nom';
    } else if (prenom != null) {
      return prenom!;
    } else if (nom != null) {
      return nom!;
    }
    return email;
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tokenType: json['tokenType'],
      expiresIn: json['expiresIn'],
      user: User.fromJson(json['user']),
    );
  }
}
