const CACHE='arseny-rpg-beta-v1';
const FILES=['./', './index.html', './manifest.json', './icon.svg'];

self.addEventListener('install', e=>{
  e.waitUntil(
    caches.open(CACHE)
      .then(c=>c.addAll(FILES))
      .then(()=>self.skipWaiting())
  );
});

self.addEventListener('activate', e=>{
  e.waitUntil(
    caches.keys().then(keys=>
      Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', e=>{
  // Don't cache Supabase API calls — always fetch live
  if(e.request.url.includes('supabase.co')){
    e.respondWith(fetch(e.request));
    return;
  }
  // Cache-first for static assets
  e.respondWith(
    caches.match(e.request).then(r=>r||fetch(e.request))
  );
});
