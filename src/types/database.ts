export type ProfileRole = 'admin' | 'resident' | 'security';
export type BillStatus = 'unpaid' | 'partially_paid' | 'paid';
export type VisitorType = 'guest' | 'delivery' | 'daily_help';
export type GateLogStatus =
  | 'expected'
  | 'approved'
  | 'denied'
  | 'checked_in'
  | 'checked_out';

export type Society = {
  id: string;
  name: string;
  address: string;
  rwa_bank_details: Record<string, unknown>;
  created_at: string;
  updated_at: string;
};

export type Profile = {
  id: string;
  society_id: string;
  unit_id: string | null;
  role: ProfileRole;
  phone: string | null;
  created_at: string;
  updated_at: string;
};

/** Placeholder until Supabase CLI generates types from migrations. */
export type Database = {
  public: {
    Tables: {
      societies: { Row: Society; Insert: Partial<Society>; Update: Partial<Society> };
      profiles: { Row: Profile; Insert: Partial<Profile>; Update: Partial<Profile> };
    };
  };
};
