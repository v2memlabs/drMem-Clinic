/// Klinik / tenant — SaaS çok kiracılı izolasyon birimi.
class Tenant {
  final String id;
  final String name;
  final String specialty;

  const Tenant({
    required this.id,
    required this.name,
    this.specialty = '',
  });

  Tenant copyWith({
    String? id,
    String? name,
    String? specialty,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
    );
  }
}
