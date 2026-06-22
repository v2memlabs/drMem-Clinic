/// Operasyonel kayıtlar — Supabase şema hazırlık bayrakları.
///
/// Migration/RLS yokken remote gate kapalı kalır; mock adapter kullanılır.
/// Operational Records Remote Batch v2a: payments + consents true.
/// Operational Records Remote Batch v2b: inventory true.
/// Faz 4 Paket 1: imaging notes true.
/// Faz 4 Paket 2: exercise plans true.
/// Faz 4 Paket 3: post-op protocols true.
abstract final class OperationalRecordsRemoteCapabilities {
  static const bool paymentsTableReady = true;
  static const bool consentsTableReady = true;
  static const bool consentTemplatesTableReady = true;
  static const bool inventoryTablesReady = true;
  static const bool surgeryProcedureNotesTableReady = true;
  static const bool surgeryNoteTemplatesTableReady = true;
  static const bool paymentStaffNotificationsTableReady = true;
  static const bool imagingNotesTableReady = true;
  static const bool exercisePlansTableReady = true;
  static const bool postOpProtocolsTableReady = true;

  /// Faz 2A — muayene zinciri (20260826180000_clinical_chain_remote_v1.sql)
  static const bool prescriptionsTableReady = true;
  static const bool labOrderTemplatesTableReady = true;
  static const bool labOrdersTableReady = true;
  static const bool radiologyOrdersTableReady = true;
  static const bool clinicalReportsTableReady = true;

  /// Faz 2B — mesajlaşma (20260826190000_messaging_remote_v1.sql)
  static const bool messageTemplatesTableReady = true;
  static const bool sentMessagesTableReady = true;
}
