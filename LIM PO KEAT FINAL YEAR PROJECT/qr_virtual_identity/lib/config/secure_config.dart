class SecureConfig {
  // 🔐 HMAC Secret Key (Must match backend)
  // TODO: In production, fetch this from a secure remote config or secure storage
  static const String hmacSecret = "SUPER_SECRET_256_BIT_KEY";
}
