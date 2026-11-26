/* ============================================================
   Engineering Workshop Reports — connection settings
   Fill in the two values from your Supabase project:
   Supabase dashboard → Project Settings → API
   (the "anon public" key is meant to be in web pages; data is
   protected by staff sign-in + the rules in supabase/setup.sql)
   ============================================================ */
window.EWR_CONFIG = {
  SUPABASE_URL: "https://ojdkuufqvhcjrjbcmoaw.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9qZGt1dWZxdmhjanJqYmNtb2F3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTU2ODIxNTcsImV4cCI6MjExMTI1ODE1N30.vbxAkH9bvfIy4LnHwxdleOKTH-lMcztCK2IV8-Y7AiQ",

  // Cloud space for photos of ACTIVE jobs (free plan = 1024 MB).
  // The meter at the bottom of the job list warns at 80 %.
  CLOUD_LIMIT_MB: 1024
};
