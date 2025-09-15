class AuthModel {
  final String token;
  final String refreshToken;
  final AuthUser user;

  AuthModel({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      token: json["token"] ?? "",
      refreshToken: json["refreshToken"] ?? "",
      user: AuthUser.fromJson(json["user"] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "token": token,
      "refreshToken": refreshToken,
      "user": user.toJson(),
    };
  }
}

class AuthUser {
  final String mRepId;
  final String name;
  final String role;

  AuthUser({required this.mRepId, required this.name, required this.role});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      mRepId: json["m_rep_id"] ?? "",
      name: json["name"] ?? "",
      role: json["role"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {"m_rep_id": mRepId, "name": name, "role": role};
  }
}
