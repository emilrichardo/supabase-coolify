-- Initial schema setup for Supabase
-- This script runs when the database is first initialized

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pgjwt";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create schemas
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS extensions;

-- Move extensions to extensions schema
ALTER EXTENSION "uuid-ossp" SET SCHEMA extensions;
ALTER EXTENSION "pgcrypto" SET SCHEMA extensions;
ALTER EXTENSION "pgjwt" SET SCHEMA extensions;
ALTER EXTENSION "pg_stat_statements" SET SCHEMA extensions;

-- Grant usage on schemas
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA extensions TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA storage TO anon, authenticated, service_role;

-- Grant permissions on extensions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA extensions TO anon, authenticated, service_role;

-- Create anon role (anonymous users)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
END
$$;

-- Create authenticated role (logged in users)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
END
$$;

-- Create service_role (admin/service access)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') THEN
    CREATE ROLE service_role NOLOGIN;
  END IF;
END
$$;

-- Grant roles to authenticator (PostgREST will use this)
GRANT anon, authenticated, service_role TO authenticator;

-- Create storage schema objects
CREATE TABLE IF NOT EXISTS storage.buckets (
    id text PRIMARY KEY,
    name text NOT NULL UNIQUE,
    owner uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint DEFAULT 0,
    allowed_mime_types text[] DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS storage.objects (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    bucket_id text REFERENCES storage.buckets,
    name text,
    owner uuid,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    last_accessed_at timestamptz DEFAULT now(),
    metadata jsonb DEFAULT '{}'::jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/')) STORED,
    version text,
    owner_id text
);

-- Enable RLS on storage tables
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Create policies for storage
CREATE POLICY "Allow public access to public buckets" ON storage.buckets
    FOR SELECT USING (public = true);

CREATE POLICY "Allow authenticated users to create buckets" ON storage.buckets
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow bucket owners to update buckets" ON storage.buckets
    FOR UPDATE TO authenticated USING (owner = auth.uid());

CREATE POLICY "Allow public access to objects in public buckets" ON storage.objects
    FOR SELECT USING (
        bucket_id IN (
            SELECT id FROM storage.buckets WHERE public = true
        )
    );

CREATE POLICY "Allow authenticated users to upload objects" ON storage.objects
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Allow object owners to update objects" ON storage.objects
    FOR UPDATE TO authenticated USING (owner = auth.uid());

CREATE POLICY "Allow object owners to delete objects" ON storage.objects
    FOR DELETE TO authenticated USING (owner = auth.uid());

-- Create functions for storage
CREATE OR REPLACE FUNCTION storage.extension(name text)
RETURNS text AS $$
    SELECT split_part(name, '.', -1);
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION storage.filename(name text)
RETURNS text AS $$
    SELECT split_part(name, '/', -1);
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION storage.foldername(name text)
RETURNS text[] AS $$
    SELECT array_remove(string_to_array(name, '/'), '');
$$ LANGUAGE SQL IMMUTABLE;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION extensions.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
CREATE TRIGGER buckets_updated_at
    BEFORE UPDATE ON storage.buckets
    FOR EACH ROW
    EXECUTE FUNCTION extensions.set_updated_at();

CREATE TRIGGER objects_updated_at
    BEFORE UPDATE ON storage.objects
    FOR EACH ROW
    EXECUTE FUNCTION extensions.set_updated_at();

-- Grant permissions on storage
GRANT ALL ON TABLE storage.buckets TO anon, authenticated, service_role;
GRANT ALL ON TABLE storage.objects TO anon, authenticated, service_role;

-- Grant sequence permissions
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA storage TO anon, authenticated, service_role;

-- Create auth schema objects (basic structure, GoTrue will create the rest)
CREATE TABLE IF NOT EXISTS auth.users (
    instance_id uuid,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    aud varchar(255),
    role varchar(255),
    email varchar(255) UNIQUE,
    encrypted_password varchar(255),
    email_confirmed_at timestamptz,
    invited_at timestamptz,
    confirmation_token varchar(255),
    confirmation_sent_at timestamptz,
    recovery_token varchar(255),
    recovery_sent_at timestamptz,
    email_change_token_new varchar(255),
    email_change varchar(255),
    email_change_sent_at timestamptz,
    new_email varchar(255),
    new_phone varchar(255),
    phone varchar(255) UNIQUE,
    phone_confirmed_at timestamptz,
    phone_change varchar(255),
    phone_change_token varchar(255),
    phone_change_sent_at timestamptz,
    confirmed_at timestamptz,
    email_change_token_current varchar(255),
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamptz,
    reauthentication_token varchar(255),
    reauthentication_sent_at timestamptz,
    is_sso_user boolean DEFAULT false,
    deleted_at timestamptz,
    is_anonymous boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    raw_app_meta_data jsonb DEFAULT '{}'::jsonb,
    raw_user_meta_data jsonb DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    email text,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid()
);

CREATE TABLE IF NOT EXISTS auth.sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    factor_id uuid,
    aal text DEFAULT 'aal1',
    not_after timestamptz,
    refreshed_at timestamptz,
    user_agent text,
    ip inet,
    tag text
);

CREATE TABLE IF NOT EXISTS auth.refresh_tokens (
    instance_id uuid,
    id bigserial PRIMARY KEY,
    token varchar(255) UNIQUE,
    user_id varchar(255),
    revoked boolean,
    created_at timestamptz,
    updated_at timestamptz,
    parent varchar(255),
    session_id uuid REFERENCES auth.sessions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS auth.mfa_factors (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    friendly_name text,
    factor_type text NOT NULL,
    status text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    secret text
);

CREATE TABLE IF NOT EXISTS auth.mfa_challenges (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    factor_id uuid NOT NULL REFERENCES auth.mfa_factors(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    verified_at timestamptz,
    ip_address inet NOT NULL
);

CREATE TABLE IF NOT EXISTS auth.mfa_amr_claims (
    session_id uuid NOT NULL REFERENCES auth.sessions(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    authentication_method text NOT NULL,
    id uuid PRIMARY KEY DEFAULT gen_random_uuid()
);

CREATE TABLE IF NOT EXISTS auth.sso_providers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS auth.sso_domains (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sso_provider_id uuid NOT NULL REFERENCES auth.sso_providers(id) ON DELETE CASCADE,
    domain text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS auth.saml_providers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sso_provider_id uuid NOT NULL REFERENCES auth.sso_providers(id) ON DELETE CASCADE,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb DEFAULT '{}'::jsonb,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    name_id_format text
);

CREATE TABLE IF NOT EXISTS auth.saml_relay_states (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sso_provider_id uuid NOT NULL REFERENCES auth.sso_providers(id) ON DELETE CASCADE,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    flow_state_id uuid
);

CREATE TABLE IF NOT EXISTS auth.flow_state (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid,
    auth_code text NOT NULL,
    code_challenge_method text NOT NULL,
    code_challenge text NOT NULL,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    authentication_method text NOT NULL,
    auth_code_issued_at timestamptz
);

-- Grant permissions on auth schema
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA auth TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA auth TO service_role;

-- Create auth.uid() function
CREATE OR REPLACE FUNCTION auth.uid() 
RETURNS uuid 
LANGUAGE sql STABLE
AS $$
    SELECT 
        coalesce(
            current_setting('request.jwt.claim.sub', true),
            current_setting('request.jwt.claims', true)::jsonb->>'sub'
        )::uuid
$$;

-- Create auth.role() function
CREATE OR REPLACE FUNCTION auth.role() 
RETURNS text 
LANGUAGE sql STABLE
AS $$
    SELECT 
        coalesce(
            current_setting('request.jwt.claim.role', true),
            current_setting('request.jwt.claims', true)::jsonb->>'role'
        )::text
$$;

-- Create auth.email() function
CREATE OR REPLACE FUNCTION auth.email() 
RETURNS text 
LANGUAGE sql STABLE
AS $$
    SELECT 
        coalesce(
            current_setting('request.jwt.claim.email', true),
            current_setting('request.jwt.claims', true)::jsonb->>'email'
        )::text
$$;

-- Create auth.jwt() function
CREATE OR REPLACE FUNCTION auth.jwt()
RETURNS jsonb
LANGUAGE sql STABLE
AS $$
    SELECT 
        coalesce(
            current_setting('request.jwt.claims', true)::jsonb,
            '{}'::jsonb
        )
$$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_instance_id ON auth.users(instance_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON auth.users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON auth.users(phone);
CREATE INDEX IF NOT EXISTS idx_identities_user_id ON auth.identities(user_id);
CREATE INDEX IF NOT EXISTS idx_identities_email ON auth.identities(email);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON auth.sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_session_id ON auth.refresh_tokens(session_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON auth.refresh_tokens(token);
CREATE INDEX IF NOT EXISTS idx_mfa_factors_user_id ON auth.mfa_factors(user_id);
CREATE INDEX IF NOT EXISTS idx_mfa_challenges_factor_id ON auth.mfa_challenges(factor_id);
CREATE INDEX IF NOT EXISTS idx_mfa_amr_claims_session_id ON auth.mfa_amr_claims(session_id);
CREATE INDEX IF NOT EXISTS idx_flow_state_auth_code ON auth.flow_state(auth_code);
CREATE INDEX IF NOT EXISTS idx_saml_relay_states_for_email ON auth.saml_relay_states(for_email);
CREATE INDEX IF NOT EXISTS idx_saml_relay_states_sso_provider_id ON auth.saml_relay_states(sso_provider_id);
CREATE INDEX IF NOT EXISTS idx_saml_providers_sso_provider_id ON auth.saml_providers(sso_provider_id);
CREATE INDEX IF NOT EXISTS idx_sso_domains_sso_provider_id ON auth.sso_domains(sso_provider_id);

-- Storage indexes
CREATE INDEX IF NOT EXISTS idx_objects_bucket_id ON storage.objects(bucket_id);
CREATE INDEX IF NOT EXISTS idx_objects_name ON storage.objects(name);
CREATE INDEX IF NOT EXISTS idx_objects_owner ON storage.objects(owner);

-- Enable RLS on auth tables
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

-- Create basic RLS policies for auth
CREATE POLICY "Users can view own user data" ON auth.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Service role can manage all users" ON auth.users
    FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Create realtime schema
CREATE SCHEMA IF NOT EXISTS realtime;

-- Create _realtime schema for realtime extension
CREATE SCHEMA IF NOT EXISTS _realtime;

-- Comment explaining the initialization
COMMENT ON SCHEMA public IS 'Standard public schema';
COMMENT ON SCHEMA auth IS 'Auth schema for Supabase Auth (GoTrue)';
COMMENT ON SCHEMA storage IS 'Storage schema for Supabase Storage';
COMMENT ON SCHEMA extensions IS 'Extensions schema for PostgreSQL extensions';
