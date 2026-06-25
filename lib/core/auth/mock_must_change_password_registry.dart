/// Mock ortamında admin tarafından oluşturulan kullanıcıların ilk giriş şifre değişimi.
abstract final class MockMustChangePasswordRegistry {
  static final Set<String> _loginUsernames = {};

  static void markRequired(String loginUsername) {
    final normalized = loginUsername.trim().toLowerCase();
    if (normalized.isEmpty) return;
    _loginUsernames.add(normalized);
  }

  static bool isRequired(String loginUsername) {
    return _loginUsernames.contains(loginUsername.trim().toLowerCase());
  }

  static void clearFor(String loginUsername) {
    _loginUsernames.remove(loginUsername.trim().toLowerCase());
  }

  static void reset() {
    _loginUsernames.clear();
  }
}
