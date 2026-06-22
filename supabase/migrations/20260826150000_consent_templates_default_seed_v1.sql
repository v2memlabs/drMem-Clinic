-- =============================================================================
-- Varsayılan onam/KVKK şablonları — mevcut tenant'lar için seed
-- Prerequisite: consent_templates_and_extensions_v1
-- =============================================================================

insert into public.consent_templates (
  tenant_id,
  title,
  category,
  consent_type,
  description,
  version,
  content_body,
  document_file_name,
  required_for,
  is_active,
  is_system_seed
)
select
  t.id,
  v.title,
  v.category,
  v.consent_type,
  v.description,
  v.version,
  v.content_body,
  v.document_file_name,
  v.required_for,
  true,
  true
from public.tenants t
cross join (
  values
    (
      'KVKK Aydınlatma Metni',
      'KVKK Aydınlatma',
      'kvkkAydinlatma',
      'Kişisel verilerin işlenmesine ilişkin standart aydınlatma metni.',
      'v2.1',
      '6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında; kimlik, iletişim, sağlık ve klinik işlem verilerinizin sağlık hizmetlerinin yürütülmesi, randevu ve hasta kayıt süreçlerinin işletilmesi, yasal yükümlülüklerin yerine getirilmesi ve hasta güvenliğinin sağlanması amaçlarıyla işlenebileceği hakkında bilgilendirildim.',
      'kvkk_aydinlatma_v2.1.pdf',
      'Tüm hastalar'
    ),
    (
      'WhatsApp İletişim İzni',
      'WhatsApp / SMS İletişim İzni',
      'whatsappIzin',
      'Randevu ve bilgilendirme için WhatsApp iletişim izni.',
      'v1.2',
      'Randevu hatırlatması, randevu değişikliği/iptali ve tedavi planına ilişkin genel yönlendirmelerin cep telefonu numarama WhatsApp üzerinden iletilmesine izin veriyorum.',
      'izin_whatsapp_v1.2.pdf',
      'Mesajlaşma izni'
    ),
    (
      'E-posta İletişim İzni',
      'E-posta İletişim İzni',
      'emailIzin',
      'Rapor ve bilgilendirme e-postası gönderim izni.',
      'v1.0',
      'Randevu onayı, muayene özeti ve tedavi planına ilişkin yazılı yönlendirmelerin kayıtlı e-posta adresime iletilmesine izin veriyorum.',
      'izin_email_v1.pdf',
      'Mesajlaşma izni'
    ),
    (
      'Açık Rıza Formu',
      'Açık Rıza',
      'acikRiza',
      'Belirli işlemler için açık rıza beyanı.',
      'v1.3',
      'Tarafıma açıklanan kapsam ve amaçlarla sınırlı olmak üzere, sağlık hizmeti sürecinde gerekli kişisel ve özel nitelikli verilerimin işlenmesine ilişkin tercihimi özgür irademle beyan ederim.',
      'acik_riza_v1.3.pdf',
      'Tüm hastalar'
    )
) as v(
  title,
  category,
  consent_type,
  description,
  version,
  content_body,
  document_file_name,
  required_for
)
where not exists (
  select 1
  from public.consent_templates ct
  where ct.tenant_id = t.id
    and ct.category = v.category
    and ct.deleted_at is null
);
