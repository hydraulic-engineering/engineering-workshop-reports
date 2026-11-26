/* Engineering Workshop Reports — offline cache for the app files only.
   Network first (always the latest version when online), cached copy when offline.
   Jobs and photos are never cached here: they come live from Supabase. */
const CACHE = "ewr-v1";
const SHELL = ["./", "index.html", "config.js", "manifest.webmanifest", "supabase.js", "jszip.min.js",
  "jspdf.umd.min.js", "layout_793d.jpg", "layout_777.jpg", "icon-192.png", "icon-512.png"];
self.addEventListener("install", e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting())); });
self.addEventListener("activate", e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener("fetch", e => {
  const req = e.request; const url = new URL(req.url);
  if (req.method !== "GET" || url.origin !== self.location.origin) return;   // Supabase & other hosts: untouched
  e.respondWith(fetch(req).then(res => { if (res.ok) { const copy = res.clone(); caches.open(CACHE).then(c => c.put(req, copy)); } return res; })
    .catch(() => caches.match(req).then(r => r || caches.match("index.html"))));
});
