/// Davet / kurtarma sonrası şifre belirleme rotaları.
abstract final class AuthPasswordPaths {
  static const updatePasswordPath = '/auth/update-password';
  static const forgotPasswordPath = '/auth/forgot-password';

  static bool isUpdatePasswordPath(String location) {
    return Uri.tryParse(location)?.path == updatePasswordPath;
  }

  static bool isForgotPasswordPath(String location) {
    return Uri.tryParse(location)?.path == forgotPasswordPath;
  }

  static bool isPublicPasswordPath(String location) {
    return isUpdatePasswordPath(location) || isForgotPasswordPath(location);
  }
}
