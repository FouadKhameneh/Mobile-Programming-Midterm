import 'package:flutter/foundation.dart';

@immutable
class User {
  const User({
    required this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.isVerified = false,
    this.createdAt,
  });

  final String id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final bool isVerified;
  final DateTime? createdAt;

  String get name {
    final value = displayName?.trim();
    if (value != null && value.isNotEmpty) return value;
    if (username.trim().isNotEmpty) return username.trim();
    return email.split('@').first;
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.isEmpty ? 'S' : name[0].toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'] ?? json['createdAt'];
    return User(
      id: '${json['id'] ?? ''}',
      username: '${json['username'] ?? ''}',
      email: '${json['email'] ?? ''}',
      displayName: (json['display_name'] ?? json['displayName'])?.toString(),
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl'])?.toString(),
      isVerified: json['is_verified'] == true || json['isVerified'] == true,
      createdAt: created == null ? null : DateTime.tryParse('$created'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'username': username,
        'email': email,
        'display_name': displayName,
        'avatar_url': avatarUrl,
        'is_verified': isVerified,
        'created_at': createdAt?.toIso8601String(),
      };

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? avatarUrl,
    bool? isVerified,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
    );
  }
}
