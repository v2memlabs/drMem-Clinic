-- =============================================================================
-- Supabase seed entrypoint — LOCAL / STAGING / DEV ONLY
-- =============================================================================
-- Runs automatically on `supabase db reset` (after migrations).
-- DO NOT apply to production.
-- =============================================================================

\set ON_ERROR_STOP on
\ir seeds/staging_seed_data_v1.sql
