-- SocietySync initial schema: enums, tables, RLS, updated_at triggers

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
CREATE TYPE public.profile_role AS ENUM ('admin', 'resident', 'security');

CREATE TYPE public.bill_status AS ENUM ('unpaid', 'partially_paid', 'paid');

CREATE TYPE public.visitor_type AS ENUM ('guest', 'delivery', 'daily_help');

CREATE TYPE public.gate_log_status AS ENUM (
  'expected',
  'approved',
  'denied',
  'checked_in',
  'checked_out'
);

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------
CREATE TABLE public.societies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  address TEXT NOT NULL,
  rwa_bank_details JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  society_id UUID NOT NULL REFERENCES public.societies (id) ON DELETE CASCADE,
  block_number VARCHAR(50) NOT NULL,
  flat_number VARCHAR(50) NOT NULL,
  square_footage NUMERIC(12, 2) NOT NULL DEFAULT 0,
  current_balance NUMERIC(14, 2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (society_id, block_number, flat_number)
);

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  society_id UUID NOT NULL REFERENCES public.societies (id) ON DELETE CASCADE,
  unit_id UUID REFERENCES public.units (id) ON DELETE SET NULL,
  role public.profile_role NOT NULL,
  phone VARCHAR(20),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT profiles_unit_role_check CHECK (
    (role = 'resident' AND unit_id IS NOT NULL)
    OR (role IN ('admin', 'security') AND unit_id IS NULL)
  )
);

CREATE TABLE public.maintenance_bills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id UUID NOT NULL REFERENCES public.units (id) ON DELETE CASCADE,
  billing_period VARCHAR(50) NOT NULL,
  fixed_charge NUMERIC(14, 2) NOT NULL DEFAULT 0,
  variable_charge NUMERIC(14, 2) NOT NULL DEFAULT 0,
  late_fee_accumulated NUMERIC(14, 2) NOT NULL DEFAULT 0,
  due_date DATE NOT NULL,
  status public.bill_status NOT NULL DEFAULT 'unpaid',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (unit_id, billing_period)
);

CREATE TABLE public.gate_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  society_id UUID NOT NULL REFERENCES public.societies (id) ON DELETE CASCADE,
  unit_id UUID NOT NULL REFERENCES public.units (id) ON DELETE CASCADE,
  visitor_name VARCHAR(255) NOT NULL,
  visitor_type public.visitor_type NOT NULL DEFAULT 'guest',
  vehicle_number VARCHAR(32),
  passcode CHAR(6),
  status public.gate_log_status NOT NULL DEFAULT 'expected',
  approved_by UUID REFERENCES public.units (id) ON DELETE SET NULL,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT gate_logs_passcode_format CHECK (
    passcode IS NULL OR passcode ~ '^[0-9]{6}$'
  )
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
CREATE INDEX idx_units_society_id ON public.units (society_id);
CREATE INDEX idx_profiles_society_id ON public.profiles (society_id);
CREATE INDEX idx_profiles_unit_id ON public.profiles (unit_id);
CREATE INDEX idx_maintenance_bills_unit_id ON public.maintenance_bills (unit_id);
CREATE INDEX idx_maintenance_bills_status_due ON public.maintenance_bills (status, due_date);
CREATE INDEX idx_gate_logs_society_id ON public.gate_logs (society_id);
CREATE INDEX idx_gate_logs_unit_id ON public.gate_logs (unit_id);
CREATE INDEX idx_gate_logs_passcode ON public.gate_logs (society_id, passcode)
  WHERE passcode IS NOT NULL;

-- ---------------------------------------------------------------------------
-- updated_at trigger
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER societies_set_updated_at
  BEFORE UPDATE ON public.societies
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER units_set_updated_at
  BEFORE UPDATE ON public.units
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER profiles_set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER maintenance_bills_set_updated_at
  BEFORE UPDATE ON public.maintenance_bills
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER gate_logs_set_updated_at
  BEFORE UPDATE ON public.gate_logs
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Auth helpers for RLS
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_profile()
RETURNS public.profiles
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.*
  FROM public.profiles p
  WHERE p.id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.current_society_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT society_id FROM public.current_profile();
$$;

CREATE OR REPLACE FUNCTION public.current_role()
RETURNS public.profile_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.current_profile();
$$;

CREATE OR REPLACE FUNCTION public.current_unit_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT unit_id FROM public.current_profile();
$$;

-- Auto-create profile row hook (app should set metadata; placeholder for future)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Profiles are provisioned by admins; no automatic insert.
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.societies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gate_logs ENABLE ROW LEVEL SECURITY;

-- societies
CREATE POLICY societies_admin_select ON public.societies
  FOR SELECT TO authenticated
  USING (id = public.current_society_id() AND public.current_role() = 'admin');

CREATE POLICY societies_admin_update ON public.societies
  FOR UPDATE TO authenticated
  USING (id = public.current_society_id() AND public.current_role() = 'admin')
  WITH CHECK (id = public.current_society_id() AND public.current_role() = 'admin');

CREATE POLICY societies_member_select ON public.societies
  FOR SELECT TO authenticated
  USING (
    id = public.current_society_id()
    AND public.current_role() IN ('resident', 'security')
  );

-- units
CREATE POLICY units_admin_all ON public.units
  FOR ALL TO authenticated
  USING (
    society_id = public.current_society_id()
    AND public.current_role() = 'admin'
  )
  WITH CHECK (
    society_id = public.current_society_id()
    AND public.current_role() = 'admin'
  );

CREATE POLICY units_resident_select_own ON public.units
  FOR SELECT TO authenticated
  USING (
    public.current_role() = 'resident'
    AND id = public.current_unit_id()
  );

CREATE POLICY units_security_select_society ON public.units
  FOR SELECT TO authenticated
  USING (
    public.current_role() = 'security'
    AND society_id = public.current_society_id()
  );

-- profiles
CREATE POLICY profiles_select_same_society ON public.profiles
  FOR SELECT TO authenticated
  USING (society_id = public.current_society_id());

CREATE POLICY profiles_admin_manage ON public.profiles
  FOR ALL TO authenticated
  USING (
    society_id = public.current_society_id()
    AND public.current_role() = 'admin'
  )
  WITH CHECK (
    society_id = public.current_society_id()
    AND public.current_role() = 'admin'
  );

CREATE POLICY profiles_update_self ON public.profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- maintenance_bills (no access for security)
CREATE POLICY bills_admin_all ON public.maintenance_bills
  FOR ALL TO authenticated
  USING (
    public.current_role() = 'admin'
    AND EXISTS (
      SELECT 1 FROM public.units u
      WHERE u.id = maintenance_bills.unit_id
        AND u.society_id = public.current_society_id()
    )
  )
  WITH CHECK (
    public.current_role() = 'admin'
    AND EXISTS (
      SELECT 1 FROM public.units u
      WHERE u.id = maintenance_bills.unit_id
        AND u.society_id = public.current_society_id()
    )
  );

CREATE POLICY bills_resident_select_own ON public.maintenance_bills
  FOR SELECT TO authenticated
  USING (
    public.current_role() = 'resident'
    AND unit_id = public.current_unit_id()
  );

-- gate_logs
CREATE POLICY gate_logs_admin_all ON public.gate_logs
  FOR ALL TO authenticated
  USING (
    public.current_role() = 'admin'
    AND society_id = public.current_society_id()
  )
  WITH CHECK (
    public.current_role() = 'admin'
    AND society_id = public.current_society_id()
  );

CREATE POLICY gate_logs_resident_select_own ON public.gate_logs
  FOR SELECT TO authenticated
  USING (
    public.current_role() = 'resident'
    AND unit_id = public.current_unit_id()
  );

CREATE POLICY gate_logs_resident_insert_own ON public.gate_logs
  FOR INSERT TO authenticated
  WITH CHECK (
    public.current_role() = 'resident'
    AND unit_id = public.current_unit_id()
    AND society_id = public.current_society_id()
  );

CREATE POLICY gate_logs_resident_update_own ON public.gate_logs
  FOR UPDATE TO authenticated
  USING (
    public.current_role() = 'resident'
    AND unit_id = public.current_unit_id()
  )
  WITH CHECK (
    public.current_role() = 'resident'
    AND unit_id = public.current_unit_id()
  );

CREATE POLICY gate_logs_security_all ON public.gate_logs
  FOR ALL TO authenticated
  USING (
    public.current_role() = 'security'
    AND society_id = public.current_society_id()
  )
  WITH CHECK (
    public.current_role() = 'security'
    AND society_id = public.current_society_id()
  );

-- Realtime (gate approvals) — enable in Supabase dashboard or:
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.gate_logs;
