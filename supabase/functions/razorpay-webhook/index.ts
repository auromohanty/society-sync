/**
 * Razorpay payment webhook placeholder.
 *
 * Logic (to implement):
 * 1. Verify X-Razorpay-Signature with webhook secret.
 * 2. On payment.captured, match order to maintenance_bill / unit.
 * 3. Update bill status and unit.current_balance; emit receipt record.
 */
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    const _payload = await req.text();
    const _signature = req.headers.get('x-razorpay-signature');

    // TODO: verify signature and process event
    console.log('[razorpay-webhook] stub received event');

    return new Response(
      JSON.stringify({ ok: true, stub: true, received: true }),
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
