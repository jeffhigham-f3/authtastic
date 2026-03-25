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

class OtpAuthParser {
  static ParsedOtpAuth? parse(String raw) {
    late final Uri uri;
    try {
      uri = Uri.parse(raw.trim());
    } catch (_) {
      return null;
    }

    if (uri.scheme != 'otpauth') {
      return null;
    }

    if (uri.host.toLowerCase() != 'totp') {
      return null;
    }

    final secret = uri.queryParameters['secret']?.trim() ?? '';
    if (secret.isEmpty) {
      return null;
    }

    final decodedPath = uri.pathSegments.isEmpty
        ? ''
        : Uri.decodeComponent(uri.pathSegments.join('/'));

    String issuer = uri.queryParameters['issuer']?.trim() ?? '';
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

    if (accountName.isEmpty) {
      accountName = issuer;
    }

    return ParsedOtpAuth(
      issuer: issuer,
      accountName: accountName,
      secret: secret.replaceAll(' ', ''),
      algorithm: algorithm,
      digits: digits,
      period: period,
    );
  }
}
