/// E-posta davet / kurtarma linkinden sonra şifre belirleme gerektiğini işaretler.
abstract final class AuthPasswordSetupIntent {
  static bool _required = false;

  static bool get isRequired => _required;

  static void markRequired() {
    _required = true;
  }

  static void clear() {
    _required = false;
  }
}
