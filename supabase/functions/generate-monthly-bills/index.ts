/**
 * Scheduled: run on the 1st of each month (Supabase cron / pg_cron).
 *
 * Logic (to implement):
 * 1. For each society, load billing config (fixed monthly rate and/or per-sq-ft rate).
 * 2. For each unit in the society, insert maintenance_bills for the new billing_period.
 * 3. variable_charge = rate_per_sqft * square_footage; fixed_charge from society config.
 * 4. Set due_date (e.g. 10th of month) and status = unpaid.
 *
 * Invoke with service role; bypasses RLS.
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

    const billingPeriod = new Date().toLocaleString('en-IN', {
      month: 'short',
      year: 'numeric',
    });

    // TODO: load societies + units and insert bills
    console.log(`[generate-monthly-bills] stub run for period: ${billingPeriod}`);

    return new Response(
      JSON.stringify({
        ok: true,
        stub: true,
        billing_period: billingPeriod,
        message: 'Bill generation not implemented yet',
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
