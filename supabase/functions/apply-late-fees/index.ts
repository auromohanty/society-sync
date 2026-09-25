/**
 * Scheduled: daily (e.g. 02:00 IST).
 *
 * Logic (to implement):
 * 1. Select maintenance_bills where status != paid and due_date < today.
 * 2. Apply society-configured late fee (flat per day or compounding) to late_fee_accumulated.
 * 3. Optionally update unit.current_balance.
 */
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    );

    // TODO: query overdue bills and apply fees
    console.log('[apply-late-fees] stub run');

    return new Response(
      JSON.stringify({
        ok: true,
        stub: true,
        updated_count: 0,
        message: 'Late fee application not implemented yet',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return new Response(JSON.stringify({ ok: false, error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
