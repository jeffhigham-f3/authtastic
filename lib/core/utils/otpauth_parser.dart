class ParsedOtpAuth {
  const ParsedOtpAuth({
    required this.issuer,
    required this.accountName,
    required this.secret,
    required this.algorithm,
    required this.digits,
    required this.period,
  });

  final String issuer;
  final String accountName;
  final String secret;
  final String algorithm;
  final int digits;
  final int period;
}

final RegExp _base32Pattern = RegExp(r'^[A-Z2-7=]+$', caseSensitive: false);

class OtpAuthParser {
  static ParsedOtpAuth? parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'otpauth') return null;
    if (uri.host.toLowerCase() != 'totp') return null;

    final secret =
        uri.queryParameters['secret']?.trim().replaceAll(' ', '') ?? '';
    if (secret.isEmpty || !_base32Pattern.hasMatch(secret)) return null;

    final decodedPath = uri.pathSegments.isEmpty
        ? ''
        : Uri.decodeComponent(uri.pathSegments.join('/'));

    var issuer = uri.queryParameters['issuer']?.trim() ?? '';
    var accountName = decodedPath;

    if (decodedPath.contains(':')) {
      final parts = decodedPath.split(':');
      if (issuer.isEmpty) {
        issuer = parts.first.trim();
      }
      accountName = parts.skip(1).join(':').trim();
    }

    final digits = int.tryParse(uri.queryParameters['digits'] ?? '') ?? 6;
    final period = int.tryParse(uri.queryParameters['period'] ?? '') ?? 30;
    final algorithm = (uri.queryParameters['algorithm'] ?? 'SHA1')
        .toUpperCase();

    if (digits < 6 || digits > 8) return null;
    if (period < 15 || period > 120) return null;
    if (!const {'SHA1', 'SHA256', 'SHA512'}.contains(algorithm)) return null;

    if (accountName.isEmpty) accountName = issuer;

    return ParsedOtpAuth(
      issuer: issuer,
      accountName: accountName,
      secret: secret,
      algorithm: algorithm,
      digits: digits,
      period: period,
    );
  }
}
