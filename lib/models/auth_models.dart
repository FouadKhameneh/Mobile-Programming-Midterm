import 'package:flutter/foundation.dart';

import 'user.dart';

@immutable
class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  bool get isValid => accessToken.isNotEmpty && refreshToken.isNotEmpty;
}

@immutable
class AuthResult {
  const AuthResult({required this.tokens, this.user});

  final TokenPair tokens;
  final User? user;
}

@immutable
class OtpRequestInfo {
  const OtpRequestInfo({required this.message, this.expiresIn, this.resendAfter});

  final String message;
  final int? expiresIn;
  final int? resendAfter;
}

@immutable
class OtpVerifyResult {
  const OtpVerifyResult({required this.verified, this.auth, this.message});

  final bool verified;
  final AuthResult? auth;
  final String? message;
}

@immutable
class ApiPage<T> {
  const ApiPage({
    required this.items,
    required this.count,
    this.next,
    this.previous,
  });

  final List<T> items;
  final int count;
  final String? next;
  final String? previous;

  bool get hasMore => next != null && next!.isNotEmpty;

  static ApiPage<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final raw = json['results'] ?? json['items'] ?? json['data'] ?? <dynamic>[];
    final items = <T>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          items.add(itemParser(item));
        } else if (item is Map) {
          items.add(itemParser(Map<String, dynamic>.from(item)));
        }
      }
    }
    final count = json['count'] ?? json['total'] ?? items.length;
    return ApiPage<T>(
      items: List<T>.unmodifiable(items),
      count: count is num ? count.toInt() : int.tryParse('$count') ?? items.length,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
    );
  }
}
