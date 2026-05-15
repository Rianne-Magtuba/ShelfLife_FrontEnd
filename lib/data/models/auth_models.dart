
import 'dart:convert';

// ── Login ─────────────────────────────────────────────────────────────────────

class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});

  /// Matches LoginDTO.cs: Email, Password
  Map<String, dynamic> toJson() => {
    'Email': email,
    'Password': password,
  };
}

class LoginResponse {
  final String token;
  final String userId;
  final String username;
  final String email;

  LoginResponse({
    required this.token,
    required this.userId,
    required this.username,
    required this.email,
  });

  /// ⚠️ These keys must match what AuthController returns inside Ok(new{...})
  /// Open AuthController.cs → find the login method → look at return Ok(new {
  ///   token = ...,      ← becomes json['token']
  ///   userId = ...,     ← becomes json['userId']
  /// })
factory LoginResponse.fromJson(Map<String, dynamic> json) {
// Decode the JWT payload to extract sub
String extractSub(String token) {
try {
final parts = token.split('.');
if (parts.length != 3) return '';
// Base64 decode the payload (part 2)
String payload = parts[1];
// Pad base64 string if needed
while (payload.length % 4 != 0) payload += '=';
final decoded = utf8.decode(base64Url.decode(payload));
final map = jsonDecode(decoded) as Map<String, dynamic>;
return map['sub'] as String? ?? '';
} catch (_) {
return '';
}
}

final token = _str(json, ['token', 'Token']);

return LoginResponse(
  token:    token,
  userId:   extractSub(token), // ← decode sub from JWT itself
  username: _str(json, ['username', 'Username']),
  email:    _str(json, ['email', 'Email']),
);
}

  /// Tries multiple key casings so minor C# serializer differences don't break things.
  static String _str(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      if (json[k] != null) return json[k] as String;
    }
    throw FormatException('None of $keys found in response: $json');
  }
}

// ── Register ──────────────────────────────────────────────────────────────────

class RegisterRequest {
  final String username;
  final String email;
  final String password;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
  });

  /// Matches RegisterDTO.cs: Username, Email, Password
  Map<String, dynamic> toJson() => {
    'Username': username,
    'Email':    email,
    'Password': password,
  };
}

// ── Product (barcode catalog) ─────────────────────────────────────────────────

class ProductResponse {
  final String barcode;
  final String name;
  final String category;
  final double? weightGrams;
  final double? price;

  ProductResponse({
    required this.barcode,
    required this.name,
    required this.category,
    this.weightGrams,
    this.price,
  });

  /// Matches Product.cs entity and ProductRequestDTO.cs
  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      barcode:     (json['barcode']     ?? json['Barcode'])     as String,
      name:        (json['name']        ?? json['Name'])         as String,
      category:    (json['category']    ?? json['Category'])     as String,
      weightGrams: ((json['weightGrams'] ?? json['WeightGrams']) as num?)
          ?.toDouble(),
      price:       ((json['price']       ?? json['Price'])       as num?)
          ?.toDouble(),
    );
  }
}

class ProductRequest {
  final String barcode;
  final String name;
  final String category;
  final double? weightGrams;
  final double? price;

  ProductRequest({
    required this.barcode,
    required this.name,
    required this.category,
    this.weightGrams,
    this.price,
  });

  /// Matches ProductRequestDTO.cs
  Map<String, dynamic> toJson() => {
    'Barcode':  barcode,
    'Name':     name,
    'Category': category,
    if (weightGrams != null) 'WeightGrams': weightGrams,
    if (price != null)       'Price':       price,
  };
}