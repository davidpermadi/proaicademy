/* ProAIcademy — Supabase client + Midtrans setup.
 *
 * Reads its configuration from window.PROAI_ENV (defined in proai-env.js, which is
 * generated from environment variables — see .env.example). All values it uses are
 * public/browser-safe. Never put a service_role / Midtrans SERVER key here.
 *
 * Project: ProAIcademy (yiwgyovzohcwvqpwmesk)
 */
(function () {
  var ENV = window.PROAI_ENV || {};

  // Fallback defaults keep the app working even if proai-env.js wasn't generated.
  var SUPABASE_URL = ENV.SUPABASE_URL || 'https://yiwgyovzohcwvqpwmesk.supabase.co';
  var SUPABASE_PUBLISHABLE_KEY = ENV.SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_OMCnXrtMw-Dya2a1Z3g7HA_2GUzR0lb';

  if (!window.supabase || !window.supabase.createClient) {
    console.error('[proai] supabase-js failed to load before proai-config.js');
    return;
  }

  // Idempotent: only ever create one client (avoids "Multiple GoTrueClient instances").
  if (window.proaiSupabase) return;

  window.PROAI_SUPABASE_URL = SUPABASE_URL;
  window.PROAI_SUPABASE_KEY = SUPABASE_PUBLISHABLE_KEY;

  // Midtrans (payment gateway). The CLIENT key is safe to expose in the browser;
  // the SERVER key lives only as an Edge Function secret (MIDTRANS_SERVER_KEY).
  window.PROAI_MIDTRANS = {
    clientKey: ENV.MIDTRANS_CLIENT_KEY || '',     // blank = checkout shows "not configured"
    production: ENV.MIDTRANS_IS_PRODUCTION === true || ENV.MIDTRANS_IS_PRODUCTION === 'true',
  };

  window.proaiSupabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
  });
})();
