/// Mock backend — sabit profil kimlikleri (rol bazlı filtre testleri).
abstract final class MockProfileIds {
  static const String primaryDoctor = 'mock-doctor-profile';
  static const String assistant = 'mock-assistant-profile';
  static const String physiotherapist = 'mock-physio-profile';
  static const String nurse = 'mock-nurse-profile';
}

/// Geriye dönük uyumluluk.
const String kMockPrimaryDoctorProfileId = MockProfileIds.primaryDoctor;
